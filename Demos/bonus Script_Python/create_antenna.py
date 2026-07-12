# -*- coding: utf-8 -*-
"""
Created on Wed Jan  8 14:20:18 2025

@author: sekhars
"""

from pathlib import Path

import matlab.engine


def _publish_to_jupyter(variable_map):
    """Expose variables in the active notebook namespace when available."""
    try:
        ipython = get_ipython()
    except NameError:
        ipython = None

    if ipython is not None:
        ipython.user_ns.update(variable_map)


def _copy_to_matlab_workspace(eng, variable_map):
    for name, value in variable_map.items():
        eng.workspace[name] = value


def create_antenna(
    expose_to_jupyter=True,
    keep_matlab_open=True,
    show_plots=True,
):
    """Create the antenna and expose useful variables to Jupyter.

    Returns a dictionary containing the Python variables, MATLAB-compatible
    variables, MATLAB engine handle, and generated antenna object.
    """
    workspace_vars = {}
    eng = matlab.engine.start_matlab()

    # Define parameters for the antenna
    Lmm = 40.0
    Wmm = 30.0
    lmm = 15.0
    wmm = 7.5
    dmm = 5.0
    hmm = 1.6
    eR = 2.33

    feedparams = {
        'x0': 5e-3,  # Feed location x-coordinate in meters
        'y0': 5e-3,  # Feed location y-coordinate in meters
        'V': 1.0     # Feed excitation voltage in volts
    }

    visualize = bool(show_plots)
    design_frequency = 2.5e9

    # Match the geometry variables created inside createCShapedPatchAntenna.m.
    L = Lmm * 1e-3
    W = Wmm * 1e-3
    l = lmm * 1e-3
    w = wmm * 1e-3
    d = dmm * 1e-3
    h = hmm * 1e-3
    GPL = 1.15 * L
    GPW = 1.15 * W
    workspace_vars.update(
        {
            "eng": eng,
            "Lmm": Lmm,
            "Wmm": Wmm,
            "lmm": lmm,
            "wmm": wmm,
            "dmm": dmm,
            "hmm": hmm,
            "eR": eR,
            "L": L,
            "W": W,
            "l": l,
            "w": w,
            "d": d,
            "h": h,
            "GPL": GPL,
            "GPW": GPW,
            "feedparams": feedparams,
            "visualize": visualize,
            "design_frequency": design_frequency,
        }
    )

    # Debug: Print parameters being passed to MATLAB
    print("Inputs being passed to MATLAB:")
    print(f"Lmm: {Lmm}, Wmm: {Wmm}, lmm: {lmm}, wmm: {wmm}, dmm: {dmm}, hmm: {hmm}, eR: {eR}")
    print(f"Feed parameters: x0={feedparams['x0']}, y0={feedparams['y0']}, V={feedparams['V']}")

    # Call the MATLAB function
    try:
        # Ensure the MATLAB script is in the path
        script_dir = str(Path(__file__).resolve().parent)
        eng.addpath(script_dir, nargout=0)

        # Convert all numeric inputs to MATLAB-compatible types
        Lmm_matlab = matlab.double([Lmm])
        Wmm_matlab = matlab.double([Wmm])
        lmm_matlab = matlab.double([lmm])
        wmm_matlab = matlab.double([wmm])
        dmm_matlab = matlab.double([dmm])
        hmm_matlab = matlab.double([hmm])
        eR_matlab = matlab.double([eR])

        # Convert feedparams to MATLAB struct
        feedparams_matlab = eng.struct(
            "x0", feedparams["x0"],
            "y0", feedparams["y0"],
            "V", feedparams["V"],
        )

        matlab_workspace_vars = {
            "Lmm": Lmm_matlab,
            "Wmm": Wmm_matlab,
            "lmm": lmm_matlab,
            "wmm": wmm_matlab,
            "dmm": dmm_matlab,
            "hmm": hmm_matlab,
            "eR": eR_matlab,
            "L": L,
            "W": W,
            "l": l,
            "w": w,
            "d": d,
            "h": h,
            "GPL": GPL,
            "GPW": GPW,
            "feedparams": feedparams_matlab,
            "design_frequency": design_frequency,
        }
        _copy_to_matlab_workspace(eng, matlab_workspace_vars)

        workspace_vars.update(
            {
                "feedparams_matlab": feedparams_matlab,
                "Lmm_matlab": Lmm_matlab,
                "Wmm_matlab": Wmm_matlab,
                "lmm_matlab": lmm_matlab,
                "wmm_matlab": wmm_matlab,
                "dmm_matlab": dmm_matlab,
                "hmm_matlab": hmm_matlab,
                "eR_matlab": eR_matlab,
                "matlab_workspace_vars": matlab_workspace_vars,
            }
        )

        # Create the antenna
        antenna = eng.createCShapedPatchAntenna(
            Lmm_matlab,
            Wmm_matlab,
            lmm_matlab,
            wmm_matlab,
            dmm_matlab,
            hmm_matlab,
            eR_matlab,
            feedparams_matlab,
            visualize,
            nargout=1,
        )

        print("Antenna created successfully.")

        if show_plots:
            print("Displaying structure and radiation pattern...")
            eng.show(antenna, nargout=0)
            eng.pattern(antenna, design_frequency, nargout=0)

        matlab_workspace_vars["antenna"] = antenna
        eng.workspace["antenna"] = antenna

        workspace_vars.update(
            {
                "antenna": antenna,
            }
        )

    except Exception as e:
        workspace_vars["error"] = e
        print(f"Error: {e}")

    finally:
        if expose_to_jupyter and workspace_vars:
            _publish_to_jupyter(workspace_vars)

        if not keep_matlab_open:
            eng.quit()

    return workspace_vars

if __name__ == "__main__":
    globals().update(create_antenna(keep_matlab_open=False))


