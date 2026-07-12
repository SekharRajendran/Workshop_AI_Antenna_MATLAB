# -*- coding: utf-8 -*-
"""
Created on Tue Dec 31 15:08:38 2024

@author: sekhars
"""


import os

os.environ.setdefault(
    "MPLCONFIGDIR", os.path.join(os.path.dirname(__file__), ".matplotlib")
)

import numpy as np
import torch
import gpytorch
import matlab.engine
from gpytorch.constraints import Interval
from gpytorch.kernels import MaternKernel, ScaleKernel
from gpytorch.mlls import ExactMarginalLogLikelihood
from botorch.models import SingleTaskGP
from botorch.fit import fit_gpytorch_mll
from turbo_optimizer import TurboState, get_initial_points, generate_batch, update_state
import matplotlib.pyplot as plt


LOWER_BOUNDS = torch.tensor([0.017, 0.001, 0.0, 0.0017], dtype=torch.double)
UPPER_BOUNDS = torch.tensor([0.023, 0.004, 0.0002, 0.0034], dtype=torch.double)
PENALTY_VALUE = -1e6


def unnormalize_parameters(x):
    """Map a normalized TuRBO point in [0, 1]^4 to antenna parameters."""
    x = x.to(dtype=torch.double)
    lower_bounds = LOWER_BOUNDS.to(device=x.device)
    upper_bounds = UPPER_BOUNDS.to(device=x.device)
    return lower_bounds + x * (upper_bounds - lower_bounds)


# Define the antenna optimization objective function
def eval_objective(eng, x):
    """
    Evaluate the antenna's performance using MATLAB.
    Parameters:
    - x: Tensor of normalized input variables in [0, 1].
    Returns:
    - Objective value (bandwidth).
    """
    try:
        side, height, feed_offset_x, feed_offset_y = unnormalize_parameters(x).tolist()

        # Update MATLAB antenna parameters
        ant = eng.patchMicrostripTriangular()
        ant = eng.design(ant, 10e9)
        eng.set(ant, "Side", matlab.double([side]))
        eng.set(ant, "Height", matlab.double([height]))
        eng.set(ant, "FeedOffset", matlab.double([feed_offset_x, feed_offset_y]))

        # Compute bandwidth
        freq_range = np.linspace(8e9, 12e9, 35)
        s_params = eng.sparameters(ant, matlab.double(freq_range.tolist()))
        s11 = np.asarray(eng.abs(eng.rfparam(s_params, 1, 1)), dtype=float).ravel()
        s11_db = 20 * np.log10(np.maximum(s11, np.finfo(float).tiny))
        bandwidth_indices = np.flatnonzero(s11_db < -10)

        if len(bandwidth_indices) > 0:
            bandwidth = freq_range[bandwidth_indices[-1]] - freq_range[bandwidth_indices[0]]
        else:
            bandwidth = 0

        if not np.isfinite(bandwidth) or bandwidth <= 0:
            return PENALTY_VALUE

        return float(bandwidth)

    except Exception as e:
        print(f"Error in eval_objective: {e}")
        return PENALTY_VALUE


def standardize_objectives(Y):
    Y_std = Y.std(unbiased=False)
    if not torch.isfinite(Y_std).item() or Y_std.item() <= torch.finfo(Y.dtype).eps:
        return torch.zeros_like(Y)
    return (Y - Y.mean()) / Y_std


def main():
    eng = matlab.engine.start_matlab()
    try:
        # TuRBO Initialization
        dim = 4
        batch_size = 5
        n_init = 2 * dim
        X_turbo = get_initial_points(dim, n_init).to(dtype=torch.double)
        Y_turbo = torch.tensor(
            [eval_objective(eng, x) for x in X_turbo], dtype=torch.double
        ).unsqueeze(-1)
        state = TurboState(dim=dim, batch_size=batch_size, best_value=Y_turbo.max().item())

        # Optimization loop
        while not state.restart_triggered:
            # Fit GP model
            train_Y = standardize_objectives(Y_turbo)
            likelihood = gpytorch.likelihoods.GaussianLikelihood(
                noise_constraint=Interval(1e-6, 1e-2)
            )
            covar_module = ScaleKernel(
                MaternKernel(nu=2.5, ard_num_dims=dim),
                outputscale_constraint=Interval(0.5, 2.0),
            )
            model = SingleTaskGP(
                X_turbo, train_Y, covar_module=covar_module, likelihood=likelihood
            )
            mll = ExactMarginalLogLikelihood(model.likelihood, model)
            fit_gpytorch_mll(
                mll, optimizer_kwargs={"options": {"maxiter": 1000, "gtol": 1e-6}}
            )

            # Generate new batch
            X_next = generate_batch(
                state, model, X_turbo, train_Y, batch_size=state.batch_size
            )
            Y_next = torch.tensor(
                [eval_objective(eng, x) for x in X_next], dtype=torch.double
            ).unsqueeze(-1)

            # Update state
            state = update_state(state, Y_next)
            X_turbo = torch.cat([X_turbo, X_next], dim=0)
            Y_turbo = torch.cat([Y_turbo, Y_next], dim=0)

            # Print current progress
            print(
                f"Iteration {len(X_turbo)}: Best Value = {state.best_value}, "
                f"Length = {state.length:.2e}"
            )

        # Get the best configuration
        best_idx = Y_turbo.argmax()
        best_x = unnormalize_parameters(X_turbo[best_idx]).tolist()
        side, height, feed_offset_x, feed_offset_y = best_x

        # Update MATLAB antenna parameters for the best configuration
        ant = eng.patchMicrostripTriangular()
        ant = eng.design(ant, 10e9)
        eng.set(ant, "Side", matlab.double([side]))
        eng.set(ant, "Height", matlab.double([height]))
        eng.set(ant, "FeedOffset", matlab.double([feed_offset_x, feed_offset_y]))

        # Compute S-parameters for the best configuration
        freq_range = np.linspace(8e9, 12e9, 100)
        s_params = eng.sparameters(ant, matlab.double(freq_range.tolist()))
        s11 = np.asarray(eng.abs(eng.rfparam(s_params, 1, 1)), dtype=float).ravel()
        s11_db = 20 * np.log10(np.maximum(s11, np.finfo(float).tiny))

        # Plot the S-parameters (S11)
        plt.figure(figsize=(10, 6))
        plt.plot(freq_range / 1e9, s11_db)
        plt.title("S11 Parameter (Optimized Antenna)")
        plt.xlabel("Frequency (GHz)")
        plt.ylabel("S11 (dB)")
        plt.grid(True)
        plt.show()
    finally:
        eng.quit()


if __name__ == "__main__":
    main()
