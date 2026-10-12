# Bonus: Python and MATLAB antenna optimization

This optional example uses Python to coordinate optimization and MATLAB Engine to
evaluate a triangular patch antenna. Use a local MATLAB installation with Antenna
Toolbox and RF Toolbox. A local Python process cannot attach to MATLAB Online using
this script.

The reference Python environment is Python 3.12. From this directory, install the
[recorded dependencies](requirements.txt) in the interpreter used to run the demo:

```sh
python -m pip install -r requirements.txt
```

The recorded environment pins `matlabengine==26.1`. Check the MathWorks MATLAB
Engine/Python compatibility table for your MATLAB release and use its corresponding
Engine package if different. The main workshop MATLAB examples use R2026b; the
bonus requirements preserve their recorded environment rather than claiming it is
identical. NumPy, PyTorch, GPyTorch, BoTorch, and Matplotlib are also required.

Check imports before starting the optimization:

```sh
python -B -c "import demo_bonus_triangle_optimization; print('Imports OK')"
```

Then run:

```sh
python demo_bonus_triangle_optimization.py
```

The script starts MATLAB and performs repeated EM evaluations. Keep
`turbo_optimizer.py`, `create_antenna.py`, and `createCShapedPatchAntenna.m` beside
the main script. This is an extended activity, not an instantaneous calculation.
