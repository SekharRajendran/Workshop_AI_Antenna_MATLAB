function comparison = writeAntennaComparison(study)
%WRITEANTENNACOMPARISON Export comparison tables/figures from cached results.
%   writeAntennaComparison() loads candidate_results/study.mat. No EM solves.

outputFolder = fullfile(fileparts(mfilename("fullpath")), "candidate_results");
if nargin < 1
    saved = load(fullfile(outputFolder, "study.mat"), "study");
    study = saved.study;
end
candidateId = strings(6, 1);
dimensions = nan(6, 5);
worstS11Db = nan(6, 1);
minGainDbi = nan(6, 1);
geometryPass = false(6, 1);
matching = repmat("Pending", 6, 1);
gain = matching;
screening = matching;
validation = repmat("Not selected for finer check", 6, 1);
gainSamples = nan(5, 6);
reportRows = strings(6, 1);
for index = 1:6
    candidate = study.candidates{index};
    config = candidate.config;
    candidateId(index) = config.candidate;
    dimensions(index, :) = [config.boardSide*1e3, config.patchLength*1e3, ...
        config.patchWidth*1e3, config.height*1e3, config.boardSide^2*1e6];
    worstS11Db(index) = candidate.worstS11Db;
    minGainDbi(index) = candidate.minGainDbi;
    geometryPass(index) = candidate.geometryPass;
    gainSamples(:, index) = candidate.gainDbi;
    if candidate.complete
        matching(index) = passLabel(candidate.matchPass);
        gain(index) = passLabel(candidate.gainPass);
        screening(index) = passLabel(candidate.pass);
        if ~candidate.valid
            screening(index) = "Invalid numerical result";
        end
    end
    if isequal(index, study.selectedIndex)
        if study.selectedVerified
            validation(index) = "Verified on lambda/24";
        else
            validation(index) = "Not verified; inspect finalist data";
        end
    end
    reportRows(index) = sprintf("| %s | %.6f | %.6f | %.3f | %.4f | %.4f | %s | %s | %s |", ...
        config.candidate, dimensions(index, 1), dimensions(index, 2), ...
        dimensions(index, 5), worstS11Db(index), minGainDbi(index), ...
        matching(index), gain(index), screening(index));
end
comparison = table(candidateId, dimensions(:, 1), dimensions(:, 2), ...
    dimensions(:, 3), dimensions(:, 4), dimensions(:, 5), geometryPass, ...
    worstS11Db, minGainDbi, matching, gain, screening, validation, ...
    VariableNames=["Candidate", "BoardSide_mm", "PatchLength_mm", "PatchWidth_mm", ...
    "Height_mm", "BoardArea_mm2", "GeometryMaterialsPass", "WorstS11_dB", ...
    "MinRealizedGain_dBi", "Matching", "RealizedGain", "Screening", "Validation"]);
writetable(comparison, fullfile(outputFolder, "candidate_comparison.csv"));
writetable(array2table([study.gainFrequencyHz(:)/1e9, gainSamples], ...
    VariableNames=["Frequency_GHz", candidateId.']), fullfile(outputFolder, "gain_samples_dBi.csv"));
s11Samples = nan(numel(study.frequencyHz), 6);
for index = 1:6
    if ~isempty(study.candidates{index}.s11Evaluated)
        s11Samples(:, index) = 20*log10(abs(study.candidates{index}.s11Evaluated));
    end
end
writetable(array2table([study.frequencyHz(:)/1e9, s11Samples], ...
    VariableNames=["Frequency_GHz", candidateId.']), fullfile(outputFolder, "s11_samples_dB.csv"));
writetable(cell2table(study.callLog, VariableNames=["Candidate", "Operation", "Seconds"]), ...
    fullfile(outputFolder, "numerical_timing.csv"));

%% A readable report distinguishes sampled screening from finalist checks.
report = ["# Bounded antenna experiment results"; ""; ...
    "Generated from this session's saved numerical results. Targets were unchanged."; ""; ...
    "| Candidate | Board side (mm) | Patch length (mm) | Area (mm^2) | Worst S11 (dB) | Min realized gain (dBi) | Match | Gain | Screening |"; ...
    "|---|---:|---:|---:|---:|---:|---|---|---|"; reportRows; ""; ...
    "Screening: fixed lambda/16 maximum-edge mesh (7.647767 mm at 2.45 GHz)."; ...
    "Matching: S11 <= -10 dB at all 21 samples, 2.440:0.001:2.460 GHz, 50 ohm."; ...
    "Gain: combined-polarization broadside realized gain >= 5 dBi at 2.440, 2.445, 2.450, 2.455, 2.460 GHz."; ...
    "Broadside is +z (azimuth 0 degrees, elevation 90 degrees). Realized gain includes mismatch and loss."; ...
    "All geometry/material checks passed if GeometryMaterialsPass is true in candidate_comparison.csv."; ...
    "Each model uses copper (5.96e7 S/m, 0.03556 mm thick), air, 3.059107 mm separation, and zero tilt."; ...
    "Patch width is 55.063921 mm; notch and strip widths/length remain at the specified baseline values."; ...
    "Feed placement follows [-boardSide/2, 0]. Both square board sizes meet the 125 mm limit."; ...
    "D1 S11 was reused; its realized gain was newly calculated. Other screening results were newly generated."; ""; ...
    "Study status: " + study.status; ...
    sprintf("Numerical time including baseline: %.3f / %.0f seconds.", study.numericalSeconds, study.budgetSeconds); ...
    "No full 3D patterns were recomputed for this comparison."; ""];

if ~isempty(study.finalist) && study.finalist.complete
    fine = study.finalist;
    coarse = study.candidates{study.selectedIndex};
    inBand = study.frequencyHz >= 2.44e9 & study.frequencyHz <= 2.46e9;
    coarseS11 = 20*log10(abs(coarse.s11Evaluated(inBand)));
    fineS11 = 20*log10(abs(fine.s11Evaluated(inBand)));
    meshS11Table = table(study.frequencyHz(inBand).'/1e9, coarseS11, fineS11, fineS11-coarseS11, ...
        VariableNames=["Frequency_GHz", "Lambda16S11_dB", "Lambda24S11_dB", "FineMinusCoarse_dB"]);
    meshGainTable = table(study.gainFrequencyHz(:)/1e9, coarse.gainDbi, fine.gainDbi, ...
        fine.gainDbi-coarse.gainDbi, VariableNames=["Frequency_GHz", ...
        "Lambda16RealizedGain_dBi", "Lambda24RealizedGain_dBi", "FineMinusCoarse_dB"]);
    writetable(meshS11Table, fullfile(outputFolder, "selected_mesh_s11.csv"));
    writetable(meshGainTable, fullfile(outputFolder, "selected_mesh_gain.csv"));
    report = [report; "## Finalist: " + fine.config.candidate; ""; ...
        sprintf("Selected screening candidate: %s; finer-mesh verification passed: %d.", ...
        fine.config.candidate, study.selectedVerified); ...
        "Selection rule: smallest feasible board area, then higher minimum sampled gain, then better matching."; ...
        sprintf("Board %.6f x %.6f mm; patch %.6f x %.6f mm.", ...
        fine.config.boardSide*1e3, fine.config.boardSide*1e3, fine.config.patchLength*1e3, fine.config.patchWidth*1e3); ...
        ""; "| Metric | lambda/16 | lambda/24 | Fine minus coarse |"; ...
        "|---|---:|---:|---:|"; ...
        sprintf("| Worst band S11 (dB) | %.6f | %.6f | %+.6f |", ...
        coarse.worstS11Db, fine.worstS11Db, fine.worstS11Db-coarse.worstS11Db); ...
        sprintf("| Minimum sampled realized gain (dBi) | %.6f | %.6f | %+.6f |", ...
        coarse.minGainDbi, fine.minGainDbi, fine.minGainDbi-coarse.minGainDbi); ...
        sprintf("| Maximum complex-S interpolation error | %.9g | %.9g | -- |", ...
        coarse.maxInterpolationError, fine.maxInterpolationError); ""; ...
        "Direct interpolation checks use 2.440, 2.450 and 2.460 GHz; the complex-S tolerance is 0.01."; ...
        sprintf("Direct full-band fallback used: screening %d; fine %d.", coarse.directBandUsed, fine.directBandUsed); ...
        sprintf("Maximum frequency-by-frequency S11 mesh change: %.6f dB.", max(abs(fineS11-coarseS11))); ...
        sprintf("Maximum frequency-by-frequency realized-gain mesh change: %.6f dB.", max(abs(fine.gainDbi-coarse.gainDbi))); ...
        ""; "Only the selected candidate received the lambda/24 check. Other passing candidates have screening evidence."; ...
        "This is a two-mesh sensitivity check, not full mesh convergence qualification."; ...
        "Passing sampled gain does not prove continuous-band performance."; ...
        "Array and feed-network requirements belong to later requested studies."; ""];
    checkIndex = zeros(1, 3);
    [~, checkIndex(:)] = ismember(study.config.checkHz, study.frequencyHz);
    directTable = table(study.config.checkHz(:)/1e9, ...
        20*log10(abs(coarse.directChecks)), 20*log10(abs(fine.directChecks)), ...
        abs(coarse.directChecks-coarse.s11Interpolated(checkIndex)), ...
        abs(fine.directChecks-fine.s11Interpolated(checkIndex)), ...
        VariableNames=["Frequency_GHz", "Lambda16DirectS11_dB", "Lambda24DirectS11_dB", ...
        "Lambda16ComplexSError", "Lambda24ComplexSError"]);
    writetable(directTable, fullfile(outputFolder, "selected_direct_checks.csv"));
end
writelines(report, fullfile(outputFolder, "comparison_summary.md"));
disp(comparison);

%% Figures use only stored samples, with explicit light-theme labels.
colors = lines(6);
comparisonFigure = figure(Name="Six-candidate antenna comparison", Theme="light", ...
    Color="w", Position=[70, 70, 1320, 760]);
layout = tiledlayout(comparisonFigure, 2, 2, TileSpacing="compact", Padding="compact");
areaAxes = nexttile(layout, 1, [2, 1]);
hold(areaAxes, "on");
for index = 1:6
    if study.candidates{index}.pass
        marker = "o";
        markerColor = [0.08, 0.55, 0.24];
    else
        marker = "x";
        markerColor = [0.78, 0.22, 0.14];
    end
    scatter(areaAxes, dimensions(index, 5), minGainDbi(index), 85, markerColor, ...
        marker, LineWidth=1.8, HandleVisibility="off");
    text(areaAxes, dimensions(index, 5)+110, minGainDbi(index), candidateId(index), ...
        FontSize=11, Color=markerColor, VerticalAlignment="middle");
end
scatter(areaAxes, NaN, NaN, 85, [0.08, 0.55, 0.24], "o", LineWidth=1.8, DisplayName="Passes screening");
scatter(areaAxes, NaN, NaN, 85, [0.78, 0.22, 0.14], "x", LineWidth=1.8, DisplayName="Fails screening");
if study.selectedVerified
    fine = study.finalist;
    scatter(areaAxes, fine.config.boardSide^2*1e6, fine.minGainDbi, 170, [0.1, 0.3, 0.8], ...
        "p", "filled", DisplayName="Selected, finer mesh verified");
end
yline(areaAxes, 5, "--", "5 dBi gain target", HandleVisibility="off");
xlim(areaAxes, [9400, 16000]);
ylim(areaAxes, [4.5, max(10, max(minGainDbi)+0.4)]);
xlabel(areaAxes, "Board area (mm^2)");
ylabel(areaAxes, "Minimum sampled broadside realized gain (dBi)");
title(areaAxes, "Size versus gain");
legend(areaAxes, Location="southwest");
grid(areaAxes, "on");

s11Axes = nexttile(layout, 2);
gainAxes = nexttile(layout, 4);
hold(s11Axes, "on");
hold(gainAxes, "on");
for index = 1:6
    plot(s11Axes, study.frequencyHz/1e9, s11Samples(:, index), ...
        Color=colors(index, :), LineWidth=1.5, DisplayName=candidateId(index));
    plot(gainAxes, study.gainFrequencyHz/1e9, gainSamples(:, index), "-o", ...
        Color=colors(index, :), LineWidth=1.5, DisplayName=candidateId(index));
end
yline(s11Axes, -10, "k--", "-10 dB target", HandleVisibility="off");
yline(gainAxes, 5, "k--", "5 dBi target", HandleVisibility="off");
xlim(s11Axes, [2.44, 2.46]);
xlim(gainAxes, [2.44, 2.46]);
ylim(gainAxes, [4.5, max(10, max(gainSamples, [], "all")+0.3)]);
grid(s11Axes, "on");
grid(gainAxes, "on");
xlabel(s11Axes, "Frequency (GHz)");
ylabel(s11Axes, "S_{11} (dB), 50 \Omega");
xlabel(gainAxes, "Frequency (GHz)");
ylabel(gainAxes, "Broadside realized gain (dBi)");
title(s11Axes, "Matching: 1 MHz samples");
title(gainAxes, "Realized gain: five specified frequencies");
legend(s11Axes, Location="eastoutside");
title(layout, "Six-candidate study | Copper / air | Fixed \lambda/16 screening mesh", FontSize=15);
drawnow;
savefig(comparisonFigure, fullfile(outputFolder, "candidate_comparison.fig"));
exportgraphics(comparisonFigure, fullfile(outputFolder, "candidate_comparison.png"), Resolution=150);

if ~isempty(study.finalist) && study.finalist.complete
    meshFigure = figure(Name="Selected antenna mesh checks", Theme="light", ...
        Color="w", Position=[110, 110, 1100, 540]);
    layout = tiledlayout(meshFigure, 1, 2, TileSpacing="compact", Padding="compact");
    nexttile(layout);
    plot(study.frequencyHz(inBand)/1e9, coarseS11, "-", ...
        study.frequencyHz(inBand)/1e9, fineS11, "--", LineWidth=1.6);
    yline(-10, "k:", "Target", HandleVisibility="off");
    grid on;
    xlabel("Frequency (GHz)");
    ylabel("S_{11} (dB), 50 \Omega");
    legend("\lambda/16", "\lambda/24", Location="best");
    title("Matching sensitivity");
    nexttile(layout);
    plot(study.gainFrequencyHz/1e9, coarse.gainDbi, "-o", ...
        study.gainFrequencyHz/1e9, fine.gainDbi, "--s", LineWidth=1.6);
    grid on;
    xlabel("Frequency (GHz)");
    ylabel("Broadside realized gain (dBi)");
    legend("\lambda/16", "\lambda/24", Location="best");
    title("Gain sensitivity (expanded vertical scale)");
    title(layout, study.finalist.config.candidate + " | Two-mesh sensitivity check", FontSize=15);
    drawnow;
    savefig(meshFigure, fullfile(outputFolder, "selected_mesh_comparison.fig"));
    exportgraphics(meshFigure, fullfile(outputFolder, "selected_mesh_comparison.png"), Resolution=150);
end
end

function label = passLabel(passed)
if passed
    label = "Pass";
else
    label = "Fail";
end
end
