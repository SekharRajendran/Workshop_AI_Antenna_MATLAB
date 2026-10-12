# Reproducing the antenna demo

Open `antenna_demo.m` in MATLAB R2026b with Antenna Toolbox and RF Toolbox, then
click Run. The script includes all required MATLAB functions in one file.

The default `freshRun = false` reuses this workspace's saved baseline, study,
and selected-pattern data. It reopens saved array figures when `includeArray`
is true, or the selected element's geometry, S11, and 3D directivity when it is
false, without repeating numerical evaluations or image exports. Set
`showEarlierStages = true` to also display the baseline and comparison plots.

Set `freshRun = true` to reconstruct the baseline, evaluate all six candidates,
validate the selected element, evaluate the coupled array, and generate all outputs in a new timestamped
`Results/reproduction_*` folder. Existing results are preserved. This mode
does not need the original MAT files or the companion MATLAB function files.
Keep `antenna_demo.m` in a `Results` folder for the default relative layout.

The code retains the 180-second element and 600-second array soft numerical budgets and saves checkpoints.
Results can vary with MATLAB release and meshing; the original demonstrated
release is R2026b. Missing or failed evaluations are not treated as passes.

Original results:

- `../baseline_results/`: D1 model, sweep, directivity, and plots.
- `../candidate_results/`: all six screening candidates, the D6 finer-mesh
  checks, numerical timing, comparison tables, and plots.
- `../selected_results/`: selected model/pattern data, geometry, S11, 3D
  directivity, and `demo_checks.md`.
- `../array_results/`: four-port coupled EM results for three spacings, the
  selected finer-mesh check, currents/power checks, patterns, and summary.

`includeArray = true` includes the coupled 2x2 extension. Set it to false to
replay only the single-element demonstration. The array uses independent
boards and 1 W total incident power; physical feed-network losses are excluded.

The current array checkpoint contains all three completed screening trials.
105 mm is the provisional recommendation. The finer mesh has 17/21 direct
S-parameter samples; its gain and pattern checks remain incomplete after a
long in-flight solver call exceeded the soft budget. Default replay reports
this saved state without restarting numerical work or silently resetting the
budget. See `../array_results/array_summary.md` for the actual results.

The standalone export uses the final successful numerical and plotting
implementations from this session. Its cached replay is verified separately;
the fresh numerical workflow was already executed through those component
functions and was not repeated merely to export the code.
