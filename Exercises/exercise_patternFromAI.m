%[text] # Pattern Reconstruction with AI
%[text] Reconstruct 3-D radiation patterns from two orthogonal 2-D slices using a pretrained deep learning model. In these exercises, you will use `patternFromAI` to reconstruct full 3-D radiation patterns. Fill in the blanks marked with `% __` comments.
%%
%[text] ## Exercise 1: Sector Inverted-Amos Antenna
%[text] You have measured azimuth and elevation cuts of a sector antenna in an anechoic chamber. Visualize the slices and reconstruct the full 3-D pattern.
clear
%%
%[text] Load the pre-computed slice data.
load slicedata_sectorInvertedAmos.mat
%%
%[text] Visualize the azimuthal cut.
% __ Plot az and pA using polarpattern (hint: use TitleTop for a title)
%%
%[text] Visualize the elevation cut.
% __ Plot el and pE using polarpattern
%%
%[text] Reconstruct the full 3-D pattern from the two slices.
% __ Call patternFromAI with the elevation slice first, then azimuth slice (hint: use AngleConvention="az-el")
%%
%[text] ## Exercise 2: Rhombic Antenna
%[text] A colleague has simulated a rhombic antenna and shared az/el slice data. Reconstruct its 3-D pattern to understand its directional characteristics.
clear
%%
%[text] Load the slice data.
load slicedata_rhombic.mat
%%
%[text] Visualize the slices.
% __ Plot the azimuthal cut
%%
% __ Plot the elevation cut
%%
%[text] Reconstruct and visualize the 3-D pattern.
% __ Call patternFromAI
%%
%[text] ## Exercise 3: Imported MSI Planet File
%[text] You received measured antenna data in an MSI/Planet file (`.pln`) from a vendor. Import it and reconstruct the 3-D pattern.
clear
%%
%[text] Read the horizontal and vertical pattern data from the MSI file.
%[text] Hint: use `msiread`, which returns structs with fields like `.Azimuth`, `.Elevation`, and `.Magnitude`.
% __ Read 'Test_file_demo.pln' using msiread, returning [pA, pE]
%%
%[text] Visualize the imported slices.
% __ Plot the elevation cut (use pE.Elevation and pE.Magnitude)
%%
% __ Plot the azimuthal cut (use pA.Azimuth and pA.Magnitude)
%%
%[text] Reconstruct the 3-D pattern from the imported data.
% __ Call patternFromAI with the struct fields
%%
%[text] ## Bonus: Things to Try
%[text] Done early? Try these variations on any of the exercises above.
%[text] **Adjust transparency:**
%[text] ```matlab
%[text] opts = PatternPlotOptions(Transparency=0.6);
%[text] patternFromAI(pE,el,pA,az,AngleConvention="az-el",PatternOptions=opts)
%[text] ```
%[text] **Fix the magnitude scale for comparison across antennas:**
%[text] ```matlab
%[text] patternFromAI(pE,el,pA,az,AngleConvention="az-el",MinMaxMagnitude=[-30 10])
%[text] ```
%[text] **Return the 3-D data for further analysis:**
%[text] ```matlab
%[text] [p3D,elOut,azOut] = patternFromAI(pE,el,pA,az,AngleConvention="az-el");
%[text] size(p3D)
%[text] ```
%[text] **Compare with the analytical reconstruction (`patternFromSlices`):**
%[text] This function uses phi/theta convention. Its analytical methods (Summing, CrossWeighted) assume pattern separability, so they work well for the sector antenna and this particular MSI file, but not for the rhombic.
%[text] ```matlab
%[text] theta = 90 - el;
%[text] phi = az;
%[text] patternFromSlices(pE,theta,pA,phi)
%[text] title("patternFromSlices (Summing)")
%[text] patternFromSlices(pE,theta,pA,phi,Method="CrossWeighted")
%[text] title("patternFromSlices (CrossWeighted)")
%[text] ```
%%
%[text] *AP-S/URSI 2026 Technical Workshop — HD-7: AI in Antenna Design and Analysis: From Pretrained Models to System-Level Integration*
%[text] *Copyright 2026 The MathWorks, Inc.*
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
