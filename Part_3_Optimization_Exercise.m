%[text] # Part 3 Optimization Exercise
%[text] In this exercise, you start from the saved H-notch patch antenna MAT-file, load the antenna into PCB Antenna Designer, configure the SADEA optimization problem in the app, and run the optimizer from the app.
%[text] The input antenna is saved in `HNotchPatchUnitElement.mat` as `hNotchAnt`. The design metadata is saved as `hNotchDesign`.
requiredFiles = ["HNotchPatchUnitElement.mat","createHNotchPatchAntenna.m"];
isfile(requiredFiles)
%%
%[text] ## Load the Antenna
%[text] Load the MAT-file into the MATLAB workspace before opening the app. The app imports the `pcbStack` object from the workspace.
load("HNotchPatchUnitElement.mat","hNotchAnt","hNotchDesign")
hNotchAnt
hNotchDesign.OptimizationBoundsMillimeters
%%
%[text] ## Preview the Starting Design
%[text] The starting design is the H-notch unit element from the previous exercise. Confirm that the feed is at `[-3,-3]` mm and that the patch has top and bottom notches.
show(hNotchAnt)
title("Starting H-Notch Patch Unit Element")
%%
%[text] ## Open PCB Antenna Designer
%[text] Run this command to open PCB Antenna Designer. Keep `hNotchAnt` in the base workspace.
pcbAntennaDesigner
%%
%[text] ## Import the MAT-File Antenna into the App
%[text] In PCB Antenna Designer, use the **Import** button on the **Design** tab. If your release shows an import-from-file option, select `HNotchPatchUnitElement.mat` and choose `hNotchAnt`. If the app asks for a workspace variable, choose `hNotchAnt` from the workspace.
%[text] After import, verify that the object tree shows the H-notch PCB stack and that the 3-D view displays the patch, dielectric, ground plane, and feed.
%%
%[text] ## Set Baseline Analysis Frequencies
%[text] Before optimization, go to the **Analysis** tab and set these values so the baseline plots use the same frequencies as the optimization.
%[text] - **Center Frequency**: `4.65` GHz
%[text] - **Frequency Range**: `4:0.1:5` GHz \
centerFrequencyGHz = hNotchDesign.CenterFrequency/1e9
frequencyRangeGHz = hNotchDesign.FrequencyRange/1e9
%%
%[text] ## Open the Optimization Workflow
%[text] Click **Optimize** in the app toolstrip to open the optimization workflow. In the **OBJECTIVE FUNCTION** gallery, choose **Maximize Gain**.
%[text] Keep the main lobe direction at `[0 90]` unless the instructor asks you to optimize a different pattern direction.
%%
%[text] ## Select Design Variables
%[text] On the **Design Variables** tab, check only the four H-notch patch dimensions shown below. Enter the lower and upper bounds in millimeters.
%[text:table]
%[text] | Design Variable | Initial Value | Lower Bound | Upper Bound |
%[text] | --- | ---: | ---: | ---: |
%[text] | `Length` | `20` | `18` | `22` |
%[text] | `Width` | `20` | `18` | `22` |
%[text] | `NotchLength` | `6` | `5.4` | `6.6` |
%[text] | `NotchWidth` | `6` | `5.4` | `6.6` |
%[text:table]
%[text] Leave the board dimensions, feed location, ground plane dimensions, and center coordinates unchecked for this exercise.
%%
%[text] ## Add the S11 Constraint
%[text] On the **Constraints** tab, configure the impedance-bandwidth constraint.
%[text] - **Constraint Function**: `S11 (dB)`
%[text] - **Sign**: `<`
%[text] - **Value**: `-10`
%[text] - **Weight**: `100` \
constraintFunction = "S11 (dB)";
constraintSign = "<";
constraintValue = hNotchDesign.S11ConstraintdB
constraintWeight = 100
%%
%[text] ## Choose Optimization Options
%[text] In the optimizer settings area, use the same options as the MathWorks example.
%[text] - **Center Frequency**: `4.65` GHz
%[text] - **Frequency Range**: `4:0.1:5` GHz
%[text] - **Main Lobe**: `[0 90]`
%[text] - **Optimizer**: `SADEA`
%[text] - **Iterations**: `100`
%[text] - **Parallel Computing**: leave unchecked unless the instructor asks you to use a local parallel pool \
optimizerName = "SADEA";
iterations = 100
mainLobeDirection = hNotchDesign.MainLobeDirection
%%
%[text] ## Apply and Run
%[text] Click **Apply** after entering the design variables and constraint. Then click the green **Run** button to start SADEA optimization.
%[text] During optimization, the app first builds a surrogate model from sampled designs. After that, the app runs optimizer iterations and updates the convergence plot.
%%
%[text] ## Accept the Optimized Design
%[text] When optimization completes, click **Accept** to return to the analysis workflow with the optimized dimensions applied to the antenna.
%[text] Record the optimized values for `Length`, `Width`, `NotchLength`, and `NotchWidth` in your notes.
%%
%[text] ## Validate the Optimized Antenna
%[text] In the **Analysis** tab, rerun **Impedance**, **S Parameter**, and **3D Pattern**. Compare the optimized result with the starting design.
%[text] - Does the optimized antenna satisfy `S11 < -10 dB` over any part of `4:0.1:5` GHz?
%[text] - Did the peak gain or selected main-lobe gain improve?
%[text] - Which design variable changed the most? \
%%
%[text] ## Export the Result
%[text] Export the optimized antenna from the app to the MATLAB workspace. Use a clear variable name such as `hNotchAntOptimized`, then save it with the optimization metadata.
%[text] Run the save command after exporting `hNotchAntOptimized` from the app.
if exist("hNotchAntOptimized","var")
    save("HNotchPatchUnitElement_Optimized.mat","hNotchAntOptimized","hNotchDesign")
else
    disp("Export the optimized antenna from PCB Antenna Designer as hNotchAntOptimized, then rerun this section.")
end
%[text] *Copyright 2026 The MathWorks, Inc. Generated as a workshop exercise file.*
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
