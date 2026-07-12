# Bonus Exercise Dependencies

This folder contains the copied triangle antenna optimizer:

- `triangle_Optim_Main.py`
- `turbo_optimizer.py`
- `requirements.txt`

## Python

Use the same Python interpreter that will run the script. In this workspace, the active interpreter is Python 3.12.

Install the Python dependencies from this folder:

```powershell
python -m pip install -r requirements.txt
```

The required Python packages are:

- `numpy`
- `torch`
- `gpytorch`
- `botorch`
- `matplotlib`
- `matlabengine`

The `requirements.txt` file pins the versions that were installed and verified in this environment.

## MATLAB Engine For Python

The script imports MATLAB through:

```python
import matlab.engine
```

This requires the MATLAB Engine API for Python package:

```powershell
python -m pip install matlabengine
```

In this environment, the installed package is:

```text
matlabengine==26.1
```

The MATLAB Engine package must be installed into the same Python environment used to run `triangle_Optim_Main.py`.

## MATLAB Products

The optimizer starts MATLAB and evaluates a triangular microstrip patch antenna. MATLAB must be installed and available to the MATLAB Engine.

Required MATLAB capabilities:

- MATLAB
- Antenna Toolbox, for `patchMicrostripTriangular`, `design`, and antenna S-parameter analysis
- RF Toolbox, for `rfparam`

## Verification

From this folder, a quick import check should pass without starting the optimization:

```powershell
python -B -c "import triangle_Optim_Main; print('triangle_Optim_Main import ok')"
```

Run the optimizer with:

```powershell
python triangle_Optim_Main.py
```

The full run starts MATLAB, evaluates antenna S-parameters repeatedly, and can take a while.
