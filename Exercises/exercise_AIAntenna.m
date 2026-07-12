%[text] # Pretrained AI Antennas for Design Space Exploration
%[text] Use pretrained AI surrogate models to instantly predict antenna performance metrics without full-wave simulation. In these exercises, you will use `AIAntenna` objects to design antennas and query performance. Fill in the blanks marked with `% __` comments.
%%
%[text] ## Exercise 1: Rectangular Patch for 5.8 GHz ISM Band
%[text] You are designing a rectangular patch microstrip antenna for an ISM-band wireless link at 5.8 GHz. Your PCB layout constrains the patch width to 30 mm. Determine whether the antenna still resonates within the 5.8 GHz band and has sufficient bandwidth.
clear
%%
%[text] Design an AI-based patch microstrip antenna at 5.8 GHz.
% __ Create the AIAntenna (hint: use design with patchMicrostrip and ForAI=true)
%%
%[text] Visualize the antenna geometry.
show(pAI)
%%
%[text] View the tunable parameter ranges.
tunableRanges(pAI)
%%
%[text] Your PCB layout fixes the patch width at 30 mm. Adjust the antenna accordingly.
% __ (hint: set the width, noting that dimensions are in meters)
%%
%[text] Check the resonant frequency. Is it still near 5.8 GHz?
% __ Query the resonant frequency of pAI
%%
%[text] Check the bandwidth and whether the antenna is still matched.
% __ Query bandwidth, returning [absBW, fL, fU, matchingStatus]
%%
%[text] ## Exercise 2: Circular Patch on FR4 for 2.4 GHz Bluetooth
%[text] You need a ceiling-mounted 2.4 GHz Bluetooth antenna on FR4 substrate for indoor coverage. Your FR4 supplier reports a batch-to-batch permittivity variation. Investigate how `SubstrateEpsilonR` affects resonant frequency and beamwidth.
clear
%%
%[text] Design an AI-based circular patch antenna on FR4 at 2.4 GHz.
%[text] Hint: construct the antenna with `patchMicrostripCircular(Substrate=dielectric("FR4"))`, then pass it to `design`.
% __ Create the AIAntenna
%%
%[text] Visualize the antenna geometry.
show(pAI)
%%
%[text] View the tunable ranges. Note that `SubstrateEpsilonR` is tunable.
tunableRanges(pAI)
%%
%[text] Check the beamwidth to confirm wide angular coverage.
% __ Query beamwidth at 2.4 GHz
%%
%[text] Check the resonant frequency at the default permittivity.
% __ Query the resonant frequency
%%
%[text] Your FR4 batch measures a permittivity of 4.2 instead of the nominal 4.8. Adjust and re-check.
% __ Apply the measured permittivity
% __ Query the resonant frequency — is it still in the 2.4 GHz band (2.400–2.4835 GHz)?
% __ Query the beamwidth — is it still sufficient for coverage?
%%
%[text] ## Exercise 3: X-Band Horn for Antenna Measurements
%[text] You are setting up a 10 GHz antenna measurement range and need a reference horn with at least 15.7 dBi gain. Design one and check if it meets spec. If not, increase the flare dimensions.
clear
%%
%[text] Design an AI-based horn antenna at 10 GHz.
% __ Create the AIAntenna
%%
%[text] Visualize the antenna geometry.
show(pAI)
%%
%[text] View the tunable ranges.
tunableRanges(pAI)
%%
%[text] Query the peak radiation. Does it meet the 15.7 dBi requirement?
% __ Query the peak radiation at 10 GHz, returning [rad, az, el]
%%
%[text] The default gain is about 15.5 dBi — just under spec. Increase the flare dimensions and re-query.
% __ (hint: try flare length of 0.055 and flare height of 0.065)
% __ Query the peak radiation again
%%
%[text] ## Bonus: Things to Try
%[text] Done early? Try these variations.
%[text] **Switch the substrate material entirely and compare:**
%[text] ```matlab
%[text] pAI = design(patchMicrostripCircular(Substrate=dielectric("Teflon")),2.4e9,ForAI=true);
%[text] resonantFrequency(pAI)
%[text] bandwidth(pAI)
%[text] ```
%[text] **Sweep a tunable parameter and plot the trend:**
%[text] ```matlab
%[text] pAI = design(patchMicrostrip,5.8e9,ForAI=true);
%[text] lengths = linspace(0.021,0.028,10);
%[text] bw = zeros(size(lengths));
%[text] for i = 1:numel(lengths)
%[text]     pAI.Length = lengths(i);
%[text]     bw(i) = bandwidth(pAI);
%[text] end
%[text] plot(lengths*1e3,bw/1e6)
%[text] xlabel("Patch Length (mm)")
%[text] ylabel("Bandwidth (MHz)")
%[text] ```
%[text] **Export and validate with full-wave simulation:**
%[text] ```matlab
%[text] pm = exportAntenna(pAI);
%[text] f0 = pAI.InitialDesignFrequency;
%[text] freq = linspace(0.7,1.3,101)*f0;
%[text] fR_EM = resonantFrequency(pm,freq);
%[text] bw_EM = bandwidth(pm,freq);
%[text] hpbw_p1_EM = beamwidth(pm,f0,0,0:360); % elevation plane, az=0
%[text] hpbw_p2_EM = beamwidth(pm,f0,90,0:360); % elevation plane, az=90 (patches)
%[text] % hpbw_p2_EM = beamwidth(pm,f0,0:360,0); % azimuth plane, el=0 (horns)
%[text] [rad_EM,az,el] = peakRadiation(pm,f0,0:360,-90:90);
%[text] ```
%[text] For patch antennas, beamwidth is computed in two elevation planes (az=0 and az=90). For horn antennas, it is computed in the elevation plane (az=0) and the azimuth plane (el=0). Comment/uncomment the appropriate plane 2 lines accordingly.
%[text] **Compare AI surrogate speed vs. full-wave:**
%[text] ```matlab
%[text] tic; fR_AI = resonantFrequency(pAI); toc
%[text] tic; fR_EM = resonantFrequency(pm,freq); toc
%[text] tic; bw_AI = bandwidth(pAI); toc
%[text] tic; bw_EM = bandwidth(pm,freq); toc
%[text] tic; hpbw_AI = beamwidth(pAI,f0); toc
%[text] tic; hpbw_p1_EM = beamwidth(pm,f0,0,0:360); toc ; % elevation plane, az=0
%[text] tic; hpbw_p2_EM = beamwidth(pm,f0,90,0:360); toc ; % elevation plane, az=90 (patches)
%[text] % tic; hpbw_p2_EM = beamwidth(pm,f0,0:360,0); toc ; % azimuth plane, el=0 (horns)
%[text] tic; rad_AI = peakRadiation(pAI,f0); toc
%[text] tic; rad_EM = peakRadiation(pm,f0,0:360,-90:90); toc
%[text] table([fR_AI;bw_AI;hpbw_AI(1);hpbw_AI(2);rad_AI], ...
%[text]     [fR_EM;bw_EM;hpbw_p1_EM;hpbw_p2_EM;rad_EM], ...
%[text]     VariableNames=["AI","EM"], ...
%[text]     RowNames=["Resonant Frequency","10-dB Bandwidth", ...
%[text]     "3-dB Beamwidth (Plane 1)","3-dB Beamwidth (Plane 2)","Peak Radiation"])
%[text] ```
%[text] Comment/uncomment the plane 2 lines as discussed above.
%%
%[text] *AP-S/URSI 2026 Technical Workshop — HD-7: AI in Antenna Design and Analysis: From Pretrained Models to System-Level Integration*
%[text] *Copyright 2026 The MathWorks, Inc.*
%[appendix]{"version":"1.0"}
%---
%[metadata:view]
%   data: {"layout":"inline"}
%---
