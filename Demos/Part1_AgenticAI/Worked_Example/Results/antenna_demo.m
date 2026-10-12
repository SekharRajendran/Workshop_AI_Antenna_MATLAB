%% Antenna demonstration: baseline, bounded selection, and coupled 2x2 array
% Reproduce the complete workflow using the final successful session code.
% Required products: MATLAB R2026b, Antenna Toolbox, and RF Toolbox.
% This file is self-contained: all model, analysis, and plot functions follow.
% No earlier-session workspace variables or external MATLAB helpers are used.
% Model dimensions and experiment levels are fixed in the model setup below.

%% Configuration
% Default: reuse saved results in the workspace containing this Results folder.
% Set freshRun=true to rebuild everything in a new, timestamped output folder.
freshRun = false;
showEarlierStages = false;
includeArray = true;
scriptFolder = fileparts(mfilename("fullpath"));
workspaceFolder = fileparts(scriptFolder);

%% Output folder
% A fresh run preserves the original study and all previously saved results.
if freshRun
    runFolder = fullfile(scriptFolder, "reproduction_" + ...
        string(datetime("now", Format="yyyyMMdd_HHmmss_SSS"))); %#ok<UNRCH> Enabled by freshRun=true.
    mkdir(runFolder);
else
    runFolder = workspaceFolder;
end

%% Execute or replay
% The baseline and six-candidate study checkpoint after numerical calls.
% The original 180-second soft numerical budget includes baseline work.
% Replaying completed results and figures does not repeat the EM solves.
[baseline, antennaStudy, selectedAntenna, coupledArrayStudy] = ...
    replayAntennaDemo(runFolder, showEarlierStages, includeArray);

%% Results
% baseline_results: D1 model, samples, figures, and report.
% candidate_results: six candidates, selected mesh checks, and comparisons.
% selected_results: selected model, directivity data, three views, demo_checks.md.
% array_results: coupled S-matrices, spacing checks, array patterns, and report.
fprintf("Antenna demo outputs: %s\n", runFolder);

%% Workflow and model implementations
% Functions below are the final successful versions used in this session.
% They use the run folder established by replayAntennaDemo for all I/O.
function [baseline, antennaStudy, selectedAntenna, coupledArrayStudy] = ...
        replayAntennaDemo(runFolder, showEarlierStages, includeArray)
originalFolder = pwd;
restoreFolder = onCleanup(@() cd(originalFolder));
cd(runFolder);
baselineFile = fullfile(runFolder, "baseline_results", "baseline.mat");
if isfile(baselineFile)
    saved = load(baselineFile, "baseline");
    baseline = saved.baseline;
    if showEarlierStages
        plotBaselineAntenna(baseline);
    end
else
    baseline = runBaselineAntenna();
end
studyFile = fullfile(runFolder, "candidate_results", "study.mat");
if isfile(studyFile)
    saved = load(studyFile, "study");
    antennaStudy = saved.study;
    if ~startsWith(antennaStudy.status, "complete")
        antennaStudy = runBoundedAntennaStudy();
    end
else
    antennaStudy = runBoundedAntennaStudy();
end
if showEarlierStages || ~isfile(fullfile(runFolder, "candidate_results", "comparison_summary.md"))
    writeAntennaComparison(antennaStudy);
    plotBoardAreaGain();
end
selectedAntenna = [];
if antennaStudy.selectedVerified
    selectedFile = fullfile(runFolder, "selected_results", "selected.mat");
    if isfile(selectedFile) && ~showEarlierStages
        savedSelected = load(selectedFile, "selected");
        selectedAntenna = savedSelected.selected;
        if ~includeArray
            openfig(fullfile(runFolder, "selected_results", "selected_geometry.fig"), "reuse");
            openfig(fullfile(runFolder, "selected_results", "selected_s11.fig"), "reuse");
            openfig(fullfile(runFolder, "selected_results", "selected_directivity_3d.fig"), "reuse");
        end
    else
        selectedAntenna = showSelectedAntenna();
    end
else
    warning("antennaDemo:NoSelection", ...
        "No verified finalist is available. Inspect the saved candidate results and status.");
end
coupledArrayStudy = [];
if includeArray && antennaStudy.selectedVerified
    arrayFile = fullfile(runFolder, "array_results", "array_study.mat");
    if isfile(arrayFile)
        savedArray = load(arrayFile, "arrayStudy");
        coupledArrayStudy = savedArray.arrayStudy;
    end
    if isempty(coupledArrayStudy) || (~startsWith(coupledArrayStudy.status, "complete") && ...
            coupledArrayStudy.status ~= "budget_exhausted")
        coupledArrayStudy = runCoupledArrayStudy();
    end
    if isfile(fullfile(runFolder, "array_results", "array_summary.md")) && ~showEarlierStages
        disp(readtable(fullfile(runFolder, "array_results", "spacing_comparison.csv")));
        openfig(fullfile(runFolder, "array_results", "array_geometry.fig"), "reuse");
        openfig(fullfile(runFolder, "array_results", "array_spacing_comparison.fig"), "reuse");
        openfig(fullfile(runFolder, "array_results", "array_port_curves.fig"), "reuse");
        patternFile = fullfile(runFolder, "array_results", "array_realized_gain_3d.fig");
        if isfile(patternFile)
            openfig(patternFile, "reuse");
        end
    else
        reportCoupledArrayStudy(coupledArrayStudy);
    end
end
end

function baseline = runBaselineAntenna()
%RUNBASELINEANTENNA Build and evaluate the specified fresh D1 antenna.
%   baseline = runBaselineAntenna() saves checkpoints and figures beside this
%   file. Use plotBaselineAntenna() to redisplay saved results without solving.

outputFolder = fullfile(pwd(), "baseline_results");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
checkpointFile = fullfile(outputFolder, "baseline.mat");

%% Requirements: geometry in SI units, catalog finite-conductivity copper.
config = struct( ...
    "candidate", "D1", ...
    "centerHz", 2.45e9, ...
    "referenceOhm", 50, ...
    "boardSide", 122.364285e-3, ...
    "patchLength", 55.063921e-3, ...
    "patchWidth", 55.063921e-3, ...
    "height", 3.059107e-3, ...
    "notchLength", 8.157618e-3, ...
    "notchWidth", 6.118213e-3, ...
    "stripWidth", 3.496122e-3, ...
    "maxEdgeLength", 299792458/2.45e9/16, ...
    "bandHz", (2440:2460)*1e6, ...
    "contextHz", (2200:5:2700)*1e6, ...
    "checkHz", [2440, 2450, 2460]*1e6, ...
    "interpolationTolerance", 0.01);
antenna = patchMicrostripInsetfed( ...
    Length=config.patchLength, Width=config.patchWidth, ...
    Height=config.height, ...
    GroundPlaneLength=config.boardSide, ...
    GroundPlaneWidth=config.boardSide, ...
    NotchLength=config.notchLength, NotchWidth=config.notchWidth, ...
    StripLineWidth=config.stripWidth, ...
    FeedOffset=[-config.boardSide/2, 0], PatchCenterOffset=[0, 0], ...
    Substrate=dielectric("Air"), Conductor=metal("Copper"), Tilt=0);
assert(isfinite(antenna.Conductor.Conductivity), ...
    "Baseline requires finite-conductivity copper.");
baseline = struct("config", config, "antenna", antenna, ...
    "matlabVersion", version, "created", string(datetime("now")), ...
    "status", "geometry_created", "numericalSeconds", 0);
save(checkpointFile, "baseline");

%% Fixed lambda/16 screening mesh, shared by all frequency evaluations.
timer = tic;
baseline.mesh = mesh(antenna, MaxEdgeLength=config.maxEdgeLength);
meshconfig(antenna, "manual");
baseline.numericalSeconds = baseline.numericalSeconds + toc(timer);
fprintf("D1 mesh fixed: maximum edge %.6f mm.\n", config.maxEdgeLength*1e3);

%% Fast adaptive interpolation, including every 1 MHz point in the demo band.
baseline.frequencyHz = unique([config.contextHz, config.bandHz]);
timer = tic;
[baseline.sInterpolated, baseline.sweep] = sparameters( ...
    antenna, baseline.frequencyHz, config.referenceOhm, SweepOption="interp");
baseline.sweepSeconds = toc(timer);
baseline.numericalSeconds = baseline.numericalSeconds + baseline.sweepSeconds;
baseline.s11Interpolated = reshape(baseline.sInterpolated.Parameters, [], 1);
baseline.status = "interpolated_sweep_complete";
save(checkpointFile, "baseline");
fprintf("Interpolating sweep complete: %d output samples in %.2f s.\n", ...
    numel(baseline.frequencyHz), baseline.sweepSeconds);

%% Validate interpolation against direct solves at the edges and center.
timer = tic;
baseline.sDirectChecks = sparameters(antenna, config.checkHz, ...
    config.referenceOhm, SweepOption="direct");
baseline.numericalSeconds = baseline.numericalSeconds + toc(timer);
[~, checkIndex] = ismember(config.checkHz, baseline.frequencyHz);
baseline.s11DirectChecks = reshape(baseline.sDirectChecks.Parameters, [], 1);
baseline.complexSCheckError = abs( ...
    baseline.s11Interpolated(checkIndex) - baseline.s11DirectChecks);
baseline.maxComplexSCheckError = max(baseline.complexSCheckError);
baseline.interpolationPass = ...
    baseline.maxComplexSCheckError <= config.interpolationTolerance;
baseline.s11Evaluated = baseline.s11Interpolated;
baseline.bandEvaluationMethod = "validated interpolation";
if ~baseline.interpolationPass
    warning("baseline:InterpolationCheck", ...
        "Interpolation check failed; evaluating the complete demo band directly.");
    timer = tic;
    baseline.sDirectBand = sparameters(antenna, config.bandHz, ...
        config.referenceOhm, SweepOption="direct");
    baseline.numericalSeconds = baseline.numericalSeconds + toc(timer);
    [~, bandIndex] = ismember(config.bandHz, baseline.frequencyHz);
    baseline.s11Evaluated(bandIndex) = reshape(baseline.sDirectBand.Parameters, [], 1);
    baseline.bandEvaluationMethod = "direct solves (interpolation check failed)";
end
baseline.s11Db = 20*log10(abs(baseline.s11Evaluated));
baseline.inBand = baseline.frequencyHz >= config.bandHz(1) & ...
    baseline.frequencyHz <= config.bandHz(end);
baseline.worstBandS11Db = max(baseline.s11Db(baseline.inBand));
baseline.matchPass = baseline.worstBandS11Db <= -10;
baseline.centerS11Db = 20*log10(abs(baseline.s11DirectChecks(2)));
[baseline.minimumSampledS11Db, minimumIndex] = min(baseline.s11Db);
baseline.minimumSampledS11Hz = baseline.frequencyHz(minimumIndex);
baseline.status = "s11_complete";
save(checkpointFile, "baseline");

%% Combined-polarization directivity (not realized gain), no normalization.
timer = tic;
[baseline.directivityDbi, baseline.azimuthDeg, baseline.elevationDeg] = ...
    pattern(antenna, config.centerHz, -180:5:180, -90:5:90, ...
    Type="directivity", Polarization="combined", Normalize=false);
baseline.numericalSeconds = baseline.numericalSeconds + toc(timer);
baseline.broadsideDirectivityDbi = baseline.directivityDbi(end, 37);
baseline.peakSampledDirectivityDbi = max(baseline.directivityDbi, [], "all");
baseline.status = "complete";
save(checkpointFile, "baseline");

writeBaselineReport(baseline);
plotBaselineAntenna(baseline);
end

function writeBaselineReport(baseline)
%WRITEBASELINEREPORT Export numerical tables and a report from cached data.
outputFolder = fullfile(pwd(), "baseline_results");
config = baseline.config;
antenna = baseline.antenna;
%% Portable numerical exports and a concise check record.
s11Table = table(baseline.frequencyHz(:)/1e9, ...
    real(baseline.s11Interpolated), imag(baseline.s11Interpolated), ...
    baseline.s11Db, baseline.inBand(:), ...
    VariableNames=["Frequency_GHz", "InterpS11Real", "InterpS11Imag", ...
    "EvaluatedS11_dB", "InDemoBand"]);
writetable(s11Table, fullfile(outputFolder, "baseline_s11.csv"));
checkTable = table(config.checkHz(:)/1e9, ...
    20*log10(abs(baseline.s11DirectChecks)), baseline.complexSCheckError, ...
    VariableNames=["Frequency_GHz", "DirectS11_dB", "ComplexSAbsoluteError"]);
writetable(checkTable, fullfile(outputFolder, "baseline_direct_checks.csv"));
summary = sprintf(join([ ...
    "Baseline D1: physical patchMicrostripInsetfed; MATLAB %s\n" ...
    "Board: %.6f x %.6f mm; patch: %.6f x %.6f mm; air gap: %.6f mm\n" ...
    "Copper conductivity: %.8g S/m; catalog thickness: %.6f mm\n" ...
    "Fixed lambda/16 maximum edge: %.6f mm at 2.45 GHz\n" ...
    "SweepOption=interp; 2.20-2.70 GHz context at 5 MHz, demo band at 1 MHz\n" ...
    "Interpolation sweep: %.3f s; total numerical work: %.3f s\n" ...
    "Maximum complex-S check error: %.8g (limit 0.01); pass: %d\n" ...
    "Band evaluation: %s\n" ...
    "S11 at 2.45 GHz (direct): %.4f dB\n" ...
    "Worst sampled S11 in 2.44-2.46 GHz: %.4f dB; match pass: %d\n" ...
    "Minimum sampled S11: %.4f dB at %.6f GHz\n" ...
    "Broadside directivity at 2.45 GHz: %.4f dBi\n" ...
    "Peak sampled directivity at 2.45 GHz: %.4f dBi\n" ...
    "Directivity is not realized gain. Gain qualification and lambda/24 check are pending.\n" ...
    "This is the baseline only; no six-candidate or array study was performed.\n"], ""), ...
    baseline.matlabVersion, config.boardSide*1e3, config.boardSide*1e3, ...
    config.patchLength*1e3, config.patchWidth*1e3, config.height*1e3, ...
    antenna.Conductor.Conductivity, antenna.Conductor.Thickness*1e3, ...
    config.maxEdgeLength*1e3, baseline.sweepSeconds, baseline.numericalSeconds, ...
    baseline.maxComplexSCheckError, baseline.interpolationPass, ...
    baseline.bandEvaluationMethod, baseline.centerS11Db, ...
    baseline.worstBandS11Db, baseline.matchPass, baseline.minimumSampledS11Db, ...
    baseline.minimumSampledS11Hz/1e9, baseline.broadsideDirectivityDbi, ...
    baseline.peakSampledDirectivityDbi);
writelines(summary, fullfile(outputFolder, "baseline_summary.txt"));
fprintf("%s\n", summary);
end

function figures = plotBaselineAntenna(baseline)
%PLOTBASELINEANTENNA Show/export saved baseline results without EM solves.
%   plotBaselineAntenna() loads baseline_results/baseline.mat.

outputFolder = fullfile(pwd(), "baseline_results");
if nargin < 1
    saved = load(fullfile(outputFolder, "baseline.mat"), "baseline");
    baseline = saved.baseline;
end
figures = gobjects(1, 3);

figures(1) = figure(Name="Baseline D1 - antenna geometry", Theme="light", Color="w", ...
    Position=[60, 80, 1000, 720]);
show(baseline.antenna);
view(35, 25);
sgtitle(figures(1), {"Baseline D1: inset-fed copper patch / air substrate", ...
    "Board 122.364 mm | Patch 55.064 x 55.064 mm | Air gap 3.059 mm"}, ...
    FontSize=14, FontWeight="bold");
drawnow;
savefig(figures(1), fullfile(outputFolder, "baseline_geometry.fig"));
exportgraphics(figures(1), fullfile(outputFolder, "baseline_geometry.png"), Resolution=160);

figures(2) = figure(Name="Baseline D1 - S11", Theme="light", Color="w", Position=[100, 110, 1100, 650]);
layout = tiledlayout(figures(2), 1, 2, TileSpacing="compact", Padding="compact");
for panel = 1:2
    axesHandle = nexttile(layout);
    plot(axesHandle, baseline.frequencyHz/1e9, ...
        20*log10(abs(baseline.s11Interpolated)), LineWidth=1.8, ...
        DisplayName="Fast interpolating sweep");
    hold(axesHandle, "on");
    if ~baseline.interpolationPass
        plot(axesHandle, baseline.config.bandHz/1e9, ...
            baseline.s11Db(baseline.inBand), LineWidth=1.6, ...
            DisplayName="Direct band solves");
    end
    plot(axesHandle, baseline.config.checkHz/1e9, ...
        20*log10(abs(baseline.s11DirectChecks)), "o", ...
        MarkerSize=7, LineWidth=1.3, DisplayName="Direct checks");
    yline(axesHandle, -10, "--", "-10 dB target", ...
        LabelHorizontalAlignment="left", HandleVisibility="off");
    grid(axesHandle, "on");
    ylim(axesHandle, [min(-11, floor(min(baseline.s11Db))-1), 0]);
    xlabel(axesHandle, "Frequency (GHz)");
    ylabel(axesHandle, "S_{11} (dB), reference 50 \Omega");
    if panel == 1
        xlim(axesHandle, [2.20, 2.70]);
        xline(axesHandle, 2.44, ":", HandleVisibility="off");
        xline(axesHandle, 2.46, ":", HandleVisibility="off");
        title(axesHandle, "Wide-band context");
    else
        xlim(axesHandle, [2.44, 2.46]);
        title(axesHandle, "Demo band: 1 MHz output samples");
        legend(axesHandle, Location="best");
    end
end
title(layout, sprintf("Baseline D1 | S11 at 2.450 GHz: %.2f dB | Worst in band: %.2f dB", ...
    baseline.centerS11Db, baseline.worstBandS11Db), FontSize=14);
drawnow;
savefig(figures(2), fullfile(outputFolder, "baseline_s11.fig"));
exportgraphics(figures(2), fullfile(outputFolder, "baseline_s11.png"), Resolution=160);

figures(3) = figure(Name="Baseline D1 - 3D directivity at 2.45 GHz", ...
    Theme="light", Color="w", Position=[140, 140, 1050, 800]);
% Elevation increases from -90 to +90; theta increases from +z downward.
% patternCustom expects phi-by-theta, whereas pattern returns el-by-az.
patternCustom(flipud(baseline.directivityDbi).', ...
    90-fliplr(baseline.elevationDeg(:).'), baseline.azimuthDeg(:).');
sgtitle(figures(3), {"Baseline D1 | 3D directivity (dBi) at 2.450 GHz", ...
    sprintf("Combined polarization | Broadside (+z): %.2f dBi", ...
    baseline.broadsideDirectivityDbi)}, FontSize=15, FontWeight="bold");
colorScale = findall(figures(3), Type="colorbar");
for index = 1:numel(colorScale)
    colorScale(index).Label.String = "Directivity (dBi)";
end
drawnow;
savefig(figures(3), fullfile(outputFolder, "baseline_directivity_3d.fig"));
exportgraphics(figures(3), fullfile(outputFolder, "baseline_directivity_3d.png"), Resolution=160);
end

function study = runBoundedAntennaStudy()
%RUNBOUNDEDANTENNASTUDY Execute/resume the six-candidate, 180 s experiment.
%   Reuses this session's baseline. Checkpoints are saved after every call.
%   Repeated calls resume missing work rather than repeating completed solves.

rootFolder = pwd();
outputFolder = fullfile(rootFolder, "candidate_results");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
checkpoint = fullfile(outputFolder, "study.mat");
if isfile(checkpoint)
    saved = load(checkpoint, "study");
    study = saved.study;
else
    saved = load(fullfile(rootFolder, "baseline_results", "baseline.mat"), "baseline");
    baseline = saved.baseline;
    assert(abs(baseline.config.maxEdgeLength - 299792458/2.45e9/16) < 1e-12);
    assert(isequal(baseline.frequencyHz, unique([(2200:5:2700), 2440:2460])*1e6));
    baselineInfo = info(baseline.antenna);
    assert(baselineInfo.MeshingMode == "manual");
    study = struct("config", baseline.config, "frequencyHz", baseline.frequencyHz, ...
        "gainFrequencyHz", (2440:5:2460)*1e6, "budgetSeconds", 180, ...
        "numericalSeconds", baseline.numericalSeconds, ...
        "baselineSeconds", baseline.numericalSeconds, "candidates", {cell(1, 6)}, ...
        "finalist", [], "selectedIndex", [], "selectedVerified", false, ...
        "status", "screening", "matlabVersion", version, ...
        "created", string(datetime("now")), "callLog", {cell(0, 3)}, "error", "");
    boardSides = [122.364285, 100]*1e-3;
    patchLengths = [55.063921, 55.738173, 56.440519]*1e-3;
    for index = 1:6
        config = study.config;
        config.boardSide = boardSides(ceil(index/3));
        config.patchLength = patchLengths(mod(index-1, 3)+1);
        config.candidate = "D" + index;
        study.candidates{index} = initializeCandidate(config, 16);
    end
    candidate = study.candidates{1};
    candidate.antenna = baseline.antenna;
    candidate.mesh = baseline.mesh;
    candidate.meshComplete = true;
    candidate.s11Interpolated = baseline.s11Interpolated;
    candidate.s11Evaluated = baseline.s11Evaluated;
    candidate.sweep = baseline.sweep;
    candidate.directChecks = baseline.s11DirectChecks;
    candidate.maxInterpolationError = baseline.maxComplexSCheckError;
    candidate.interpolationChecked = true;
    candidate.geometryPass = checkGeometry(candidate.antenna, candidate.config);
    study.candidates{1} = candidate;
    save(checkpoint, "study");
end

try
    for index = 1:6
        study.candidates{index} = evaluateCandidate(study.candidates{index});
        candidate = study.candidates{index};
        fprintf("%s: worst S11 %.4f dB, min realized gain %.4f dBi, screening pass %d.\n", ...
            candidate.config.candidate, candidate.worstS11Db, candidate.minGainDbi, candidate.pass);
        save(checkpoint, "study");
    end

    % Validate the best screening result, reranking only for invalid interpolation.
    while isempty(study.selectedIndex)
        feasible = find(cellfun(@(candidate) candidate.pass, study.candidates));
        if isempty(feasible)
            study.status = "complete_no_screening_pass";
            break
        end
        rankValues = zeros(numel(feasible), 3);
        for rankIndex = 1:numel(feasible)
            candidate = study.candidates{feasible(rankIndex)};
            rankValues(rankIndex, :) = [candidate.config.boardSide^2, ...
                -candidate.minGainDbi, candidate.worstS11Db];
        end
        [~, order] = sortrows(rankValues, [1, 2, 3]);
        index = feasible(order(1));
        study.candidates{index} = validateInterpolation(study.candidates{index});
        if study.candidates{index}.pass
            study.selectedIndex = index;
        end
        save(checkpoint, "study");
    end

    if ~isempty(study.selectedIndex)
        if isempty(study.finalist)
            study.finalist = initializeCandidate(study.candidates{study.selectedIndex}.config, 24);
        end
        study.finalist = evaluateCandidate(study.finalist);
        study.finalist = validateInterpolation(study.finalist);
        study.selectedVerified = study.finalist.pass && study.finalist.interpolationChecked;
        study.status = "complete_finalist_checked";
        fprintf("Finalist %s lambda/24: S11 %.4f dB, gain %.4f dBi; verified pass %d.\n", ...
            study.finalist.config.candidate, study.finalist.worstS11Db, ...
            study.finalist.minGainDbi, study.selectedVerified);
    end
catch exception
    if strcmp(exception.identifier, "boundedStudy:Budget")
        study.status = "budget_exhausted";
        fprintf("Numerical budget reached; completed calls have been saved.\n");
    else
        study.status = "error";
        study.error = string(getReport(exception, "extended", "hyperlinks", "off"));
        save(checkpoint, "study");
        rethrow(exception)
    end
end
save(checkpoint, "study");
fprintf("Numerical work including baseline: %.3f / %.0f seconds.\n", ...
    study.numericalSeconds, study.budgetSeconds);

    function candidate = evaluateCandidate(candidate)
        if isempty(candidate.antenna)
            config = candidate.config;
            candidate.antenna = patchMicrostripInsetfed( ...
                Length=config.patchLength, Width=config.patchWidth, Height=config.height, ...
                GroundPlaneLength=config.boardSide, GroundPlaneWidth=config.boardSide, ...
                NotchLength=config.notchLength, NotchWidth=config.notchWidth, ...
                StripLineWidth=config.stripWidth, FeedOffset=[-config.boardSide/2, 0], ...
                PatchCenterOffset=[0, 0], Substrate=dielectric("Air"), ...
                Conductor=metal("Copper"), Tilt=0);
            candidate.geometryPass = checkGeometry(candidate.antenna, config);
        end
        if ~candidate.meshComplete
            candidate.mesh = numericalCall(@() mesh(candidate.antenna, ...
                MaxEdgeLength=candidate.maxEdgeLength), candidate, "mesh");
            meshconfig(candidate.antenna, "manual");
            candidate.meshComplete = true;
            checkpointCandidate(candidate);
        end
        if isempty(candidate.s11Interpolated)
            s = numericalCall(@() sparameters(candidate.antenna, study.frequencyHz, ...
                50, SweepOption="interp"), candidate, "interpolating sweep");
            candidate.s11Interpolated = reshape(s.Parameters, [], 1);
            candidate.s11Evaluated = candidate.s11Interpolated;
            checkpointCandidate(candidate);
        end
        for frequencyIndex = 1:5
            if isnan(candidate.gainDbi(frequencyIndex))
                candidate.gainDbi(frequencyIndex) = numericalCall(@() pattern( ...
                    candidate.antenna, study.gainFrequencyHz(frequencyIndex), 0, 90, ...
                    Type="realizedgain", Polarization="combined", Normalize=false, ...
                    Termination=50), candidate, "broadside realized gain " + frequencyIndex);
                checkpointCandidate(candidate);
            end
        end
        candidate = summarizeCandidate(candidate, study.frequencyHz);
        checkpointCandidate(candidate);
    end

    function candidate = validateInterpolation(candidate)
        if ~candidate.interpolationChecked
            s = numericalCall(@() sparameters(candidate.antenna, study.config.checkHz, ...
                50, SweepOption="direct"), candidate, "direct interpolation checks");
            candidate.directChecks = reshape(s.Parameters, [], 1);
            [~, locations] = ismember(study.config.checkHz, study.frequencyHz);
            candidate.maxInterpolationError = max(abs( ...
                candidate.directChecks - candidate.s11Interpolated(locations)));
            candidate.interpolationChecked = true;
            checkpointCandidate(candidate);
        end
        if candidate.maxInterpolationError > study.config.interpolationTolerance && ~candidate.directBandUsed
            s = numericalCall(@() sparameters(candidate.antenna, study.config.bandHz, ...
                50, SweepOption="direct"), candidate, "direct band fallback");
            [~, locations] = ismember(study.config.bandHz, study.frequencyHz);
            candidate.s11Evaluated(locations) = reshape(s.Parameters, [], 1);
            candidate.directBandUsed = true;
        end
        candidate = summarizeCandidate(candidate, study.frequencyHz);
        checkpointCandidate(candidate);
    end

    function output = numericalCall(operation, candidate, label)
        if study.numericalSeconds >= study.budgetSeconds
            error("boundedStudy:Budget", "The soft numerical budget has been reached.");
        end
        timer = tic;
        try
            output = operation();
        catch exception
            elapsed = toc(timer);
            study.numericalSeconds = study.numericalSeconds + elapsed;
            study.callLog(end+1, :) = {candidate.config.candidate, label + " FAILED", elapsed};
            save(checkpoint, "study");
            rethrow(exception)
        end
        elapsed = toc(timer);
        study.numericalSeconds = study.numericalSeconds + elapsed;
        study.callLog(end+1, :) = {candidate.config.candidate, ...
            "lambda/" + candidate.meshDivisor + " " + label, elapsed};
    end

    function checkpointCandidate(candidate)
        if candidate.meshDivisor == 16
            study.candidates{str2double(extractAfter(candidate.config.candidate, "D"))} = candidate;
        else
            study.finalist = candidate;
        end
        save(checkpoint, "study");
    end
end

function candidate = initializeCandidate(config, divisor)
candidate = struct("config", config, "meshDivisor", divisor, ...
    "maxEdgeLength", 299792458/config.centerHz/divisor, "antenna", [], ...
    "mesh", [], "meshComplete", false, "geometryPass", false, ...
    "s11Interpolated", [], "s11Evaluated", [], "sweep", [], ...
    "gainDbi", nan(5, 1), "directChecks", [], "maxInterpolationError", NaN, ...
    "interpolationChecked", false, "directBandUsed", false, ...
    "worstS11Db", NaN, "minGainDbi", NaN, "matchPass", false, ...
    "gainPass", false, "pass", false, "complete", false, "valid", false);
end

function result = checkGeometry(antenna, config)
actual = [antenna.Length, antenna.Width, antenna.Height, ...
    antenna.GroundPlaneLength, antenna.GroundPlaneWidth, antenna.NotchLength, ...
    antenna.NotchWidth, antenna.StripLineWidth, antenna.FeedOffset, ...
    antenna.PatchCenterOffset, antenna.Tilt];
expected = [config.patchLength, config.patchWidth, config.height, ...
    config.boardSide, config.boardSide, config.notchLength, config.notchWidth, ...
    config.stripWidth, -config.boardSide/2, 0, 0, 0, 0];
result = isa(antenna, "patchMicrostripInsetfed") && all(abs(actual-expected) < 1e-12) && ...
    config.boardSide <= 0.125 && antenna.Substrate.EpsilonR == 1 && ...
    antenna.Substrate.LossTangent == 0 && ...
    abs(antenna.Conductor.Conductivity-5.96e7) < 1 && ...
    abs(antenna.Conductor.Thickness-3.556e-5) < 1e-12;
assert(result, "Candidate geometry/materials do not match the requirements.");
end

function candidate = summarizeCandidate(candidate, frequencyHz)
inBand = frequencyHz >= 2.44e9 & frequencyHz <= 2.46e9;
candidate.complete = ~isempty(candidate.s11Evaluated) && all(isfinite(candidate.gainDbi));
candidate.valid = candidate.complete && all(isfinite(candidate.s11Evaluated)) && ...
    all(abs(candidate.s11Evaluated) <= 1+1e-6);
if ~isempty(candidate.s11Evaluated)
    candidate.worstS11Db = max(20*log10(abs(candidate.s11Evaluated(inBand))));
end
if all(isfinite(candidate.gainDbi))
    candidate.minGainDbi = min(candidate.gainDbi);
end
candidate.matchPass = candidate.worstS11Db <= -10;
candidate.gainPass = candidate.minGainDbi >= 5;
candidate.pass = candidate.geometryPass && candidate.valid && candidate.matchPass && candidate.gainPass;
end

function comparison = writeAntennaComparison(study)
%WRITEANTENNACOMPARISON Export comparison tables/figures from cached results.
%   writeAntennaComparison() loads candidate_results/study.mat. No EM solves.

outputFolder = fullfile(pwd(), "candidate_results");
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

function figureHandle = plotBoardAreaGain()
%PLOTBOARDAREAGAIN Plot cached screening data; no antenna solves are performed.
%   Worst-band gain is the minimum over the five specified gain frequencies.

outputFolder = fullfile(pwd(), "candidate_results");
saved = load(fullfile(outputFolder, "study.mat"), "study");
study = saved.study;
boardArea = cellfun(@(candidate) candidate.config.boardSide^2*1e6, study.candidates);
worstGain = cellfun(@(candidate) candidate.minGainDbi, study.candidates);
feasible = cellfun(@(candidate) candidate.pass, study.candidates);
candidateId = string(cellfun(@(candidate) candidate.config.candidate, ...
    study.candidates, UniformOutput=false));

figureHandle = figure(Name="Board area versus worst-band realized gain", ...
    Theme="light", Color="w", Position=[110, 80, 1080, 740]);
axesHandle = axes(figureHandle, Position=[0.12, 0.20, 0.83, 0.66], FontSize=12);
hold(axesHandle, "on");
scatter(axesHandle, boardArea(feasible), worstGain(feasible), 150, ...
    [0.06, 0.50, 0.25], "o", "filled", DisplayName="Feasible: matching and gain pass");
scatter(axesHandle, boardArea(~feasible), worstGain(~feasible), 110, ...
    [0.76, 0.20, 0.15], "x", LineWidth=2, DisplayName="Infeasible");
if ~isempty(study.selectedIndex)
    selected = study.selectedIndex;
    % Mark the screening value to keep all candidates on the same mesh.
    scatter(axesHandle, boardArea(selected), worstGain(selected), 260, ...
        [0.08, 0.30, 0.80], "p", LineWidth=1.8, DisplayName="Selected design");
end
for index = 1:numel(boardArea)
    label = sprintf("%s  |  %.2f dBi", candidateId(index), worstGain(index));
    text(axesHandle, boardArea(index)+160, worstGain(index), label, ...
        FontSize=12, VerticalAlignment="middle", Color=[0.12, 0.12, 0.12]);
end
yline(axesHandle, 5, "--", "5 dBi gain requirement", ...
    Color=[0.35, 0.35, 0.35], LineWidth=1.1, ...
    LabelHorizontalAlignment="left", HandleVisibility="off");
xlim(axesHandle, [9400, 16600]);
ylim(axesHandle, [4.65, 9.85]);
xticks(axesHandle, 10000:1000:16000);
axesHandle.XAxis.Exponent = 0;
grid(axesHandle, "on");
axesHandle.GridAlpha = 0.16;
xlabel(axesHandle, "Square-board area (mm^2)");
ylabel(axesHandle, "Minimum sampled broadside realized gain (dBi)");
title(axesHandle, {"Board area versus worst-band realized gain", ...
    "Five frequencies from 2.440 to 2.460 GHz | All points use the \lambda/16 mesh"}, ...
    FontSize=15, FontWeight="bold");
legend(axesHandle, Location="southeast", FontSize=11);
annotation(figureHandle, "textbox", [0.12, 0.025, 0.84, 0.10], ...
    String={"Feasible: S11 <= -10 dB at all 21 band samples AND realized gain >= 5 dBi at all five gain samples.", ...
    "D6 has the smallest feasible board; its separate lambda/24 and direct-S11 checks also passed."}, ...
    Interpreter="none", EdgeColor="none", FontSize=10, Color=[0.2, 0.2, 0.2]);
drawnow;
savefig(figureHandle, fullfile(outputFolder, "board_area_vs_worst_gain.fig"));
exportgraphics(figureHandle, fullfile(outputFolder, "board_area_vs_worst_gain.png"), Resolution=170);
end

function selected = showSelectedAntenna()
%SHOWSELECTEDANTENNA Show the verified finalist, S11, and 3D directivity.
%   Computes directivity once, then reuses the saved selected_results cache.
%   Does not repeat any S-parameter or realized-gain study.

rootFolder = pwd();
saved = load(fullfile(rootFolder, "candidate_results", "study.mat"), "study");
study = saved.study;
assert(study.selectedVerified, "No verified selected antenna is available.");
fine = study.finalist;
coarse = study.candidates{study.selectedIndex};
outputFolder = fullfile(rootFolder, "selected_results");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
cacheFile = fullfile(outputFolder, "selected.mat");
if isfile(cacheFile)
    saved = load(cacheFile, "selected");
    selected = saved.selected;
    assert(isequal(selected.fine.config, fine.config) && ...
        isequal(selected.fine.gainDbi, fine.gainDbi) && ...
        isequal(selected.fine.s11Evaluated, fine.s11Evaluated), ...
        "Selected cache differs from the saved study; preserve it before recomputing.");
else
    assert(study.numericalSeconds < study.budgetSeconds, "The numerical budget has been reached.");
    selected = struct("fine", fine, "coarse", coarse, "frequencyHz", study.frequencyHz, ...
        "gainFrequencyHz", study.gainFrequencyHz, "studySeconds", study.numericalSeconds, ...
        "budgetSeconds", study.budgetSeconds, "directivitySeconds", NaN, ...
        "directivityDbi", [], "azimuthDeg", [], "elevationDeg", [], ...
        "broadsideDirectivityDbi", NaN, "peakSampledDirectivityDbi", NaN, ...
        "created", string(datetime("now")), "matlabVersion", version);
    timer = tic;
    [selected.directivityDbi, selected.azimuthDeg, selected.elevationDeg] = ...
        pattern(fine.antenna, fine.config.centerHz, -180:5:180, -90:5:90, ...
        Type="directivity", Polarization="combined", Normalize=false);
    selected.directivitySeconds = toc(timer);
    [~, azimuthIndex] = min(abs(selected.azimuthDeg));
    [~, elevationIndex] = min(abs(selected.elevationDeg-90));
    selected.broadsideDirectivityDbi = selected.directivityDbi(elevationIndex, azimuthIndex);
    selected.peakSampledDirectivityDbi = max(selected.directivityDbi, [], "all");
    assert(all(isfinite(selected.directivityDbi), "all"), "Invalid directivity samples.");
    save(cacheFile, "selected");
end

%% Geometry: the actual finite-board model used for the finer-mesh checks.
config = fine.config;
figureHandle = selectedFigure("Selected antenna geometry", "selected_geometry", [70, 60, 1040, 750]);
show(fine.antenna);
view(35, 25);
sgtitle(figureHandle, {sprintf("Selected %s | Inset-fed copper patch / air substrate", config.candidate), ...
    sprintf("Board %.0f x %.0f mm | Patch %.6f x %.6f mm | Air gap %.6f mm", ...
    config.boardSide*1e3, config.boardSide*1e3, config.patchLength*1e3, ...
    config.patchWidth*1e3, config.height*1e3)}, FontSize=14, FontWeight="bold");
saveView(figureHandle, outputFolder, "selected_geometry");

%% Saved fine-mesh interpolation, with the completed direct checks overlaid.
figureHandle = selectedFigure("Selected antenna S11", "selected_s11", [100, 90, 1150, 660]);
layout = tiledlayout(figureHandle, 1, 2, TileSpacing="compact", Padding="compact");
for panel = 1:2
    axesHandle = nexttile(layout);
    plot(axesHandle, study.frequencyHz/1e9, 20*log10(abs(fine.s11Evaluated)), ...
        LineWidth=1.8, DisplayName="\lambda/24 sweep");
    hold(axesHandle, "on");
    plot(axesHandle, config.checkHz/1e9, 20*log10(abs(fine.directChecks)), ...
        "o", LineWidth=1.4, MarkerSize=7, DisplayName="Direct checks");
    yline(axesHandle, -10, "--", "-10 dB target", ...
        LabelHorizontalAlignment="left", HandleVisibility="off");
    xlabel(axesHandle, "Frequency (GHz)");
    ylabel(axesHandle, "S_{11} (dB), reference 50 \Omega");
    grid(axesHandle, "on");
    if panel == 1
        xlim(axesHandle, [2.20, 2.70]);
        xline(axesHandle, 2.44, ":", HandleVisibility="off");
        xline(axesHandle, 2.46, ":", HandleVisibility="off");
        title(axesHandle, "Wide-band context");
    else
        xlim(axesHandle, [2.44, 2.46]);
        ylim(axesHandle, [-16, -9.5]);
        title(axesHandle, "Evaluation band: 1 MHz output samples");
        legend(axesHandle, Location="southwest");
    end
end
title(layout, sprintf("Selected %s | S11 at 2.450 GHz: %.2f dB | Worst in band: %.2f dB", ...
    config.candidate, 20*log10(abs(fine.directChecks(2))), fine.worstS11Db), FontSize=14);
saveView(figureHandle, outputFolder, "selected_s11");

%% Stored combined-polarization directivity; patternCustom performs no solve.
figureHandle = selectedFigure("Selected antenna 3D directivity", "selected_directivity", [130, 110, 1050, 800]);
patternCustom(flipud(selected.directivityDbi).', ...
    90-fliplr(selected.elevationDeg(:).'), selected.azimuthDeg(:).');
sgtitle(figureHandle, {sprintf("Selected %s | 3D directivity (dBi) at 2.450 GHz", config.candidate), ...
    sprintf("Combined polarization | Broadside (+z): %.2f dBi | \\lambda/24 mesh", ...
    selected.broadsideDirectivityDbi)}, FontSize=15, FontWeight="bold");
colorScale = findall(figureHandle, Type="colorbar");
for index = 1:numel(colorScale)
    colorScale(index).Label.String = "Directivity (dBi)";
end
saveView(figureHandle, outputFolder, "selected_directivity_3d");

%% Demo checks, including the distinction between directivity and gain.
inBand = study.frequencyHz >= 2.44e9 & study.frequencyHz <= 2.46e9;
meshS11Delta = 20*log10(abs(fine.s11Evaluated(inBand))) - ...
    20*log10(abs(coarse.s11Evaluated(inBand)));
checks = ["# Selected antenna: D6 demo checks"; ""; ...
    "D6 meets the sampled single-element requirements and passed the specified finalist checks."; ...
    "D2 and D6 passed screening. D6 was selected for its smaller board area; D2 was not fine-mesh checked."; ""; ...
    "| Check | Result |"; "|---|---|"; ...
    sprintf("| Individual board size | %.0f x %.0f mm; within 125 x 125 mm |", ...
    config.boardSide*1e3, config.boardSide*1e3); ...
    sprintf("| Patch size | %.6f x %.6f mm |", config.patchLength*1e3, config.patchWidth*1e3); ...
    "| Model and materials | Physical inset-fed patch; finite copper; air; 3.059107 mm gap; zero tilt |"; ...
    sprintf("| Worst S11 over 21 samples, 2.44-2.46 GHz | %.6f dB <= -10 dB: PASS |", fine.worstS11Db); ...
    sprintf("| Minimum broadside realized gain over five frequencies | %.6f dBi >= 5 dBi: PASS |", fine.minGainDbi); ...
    sprintf("| Maximum complex-S interpolation error, lambda/16 | %.9g <= 0.01: PASS |", coarse.maxInterpolationError); ...
    sprintf("| Maximum complex-S interpolation error, lambda/24 | %.9g <= 0.01: PASS |", fine.maxInterpolationError); ...
    sprintf("| Worst-band S11 change, fine minus coarse | %+.6f dB |", fine.worstS11Db-coarse.worstS11Db); ...
    sprintf("| Minimum-gain change, fine minus coarse | %+.6f dB |", fine.minGainDbi-coarse.minGainDbi); ...
    sprintf("| Maximum samplewise S11 mesh change | %.6f dB |", max(abs(meshS11Delta))); ...
    sprintf("| Maximum samplewise gain mesh change | %.6f dB |", max(abs(fine.gainDbi-coarse.gainDbi))); ...
    sprintf("| Broadside directivity at 2.45 GHz | %.6f dBi |", selected.broadsideDirectivityDbi); ...
    sprintf("| Peak sampled 3D directivity at 2.45 GHz | %.6f dBi |", selected.peakSampledDirectivityDbi); ...
    sprintf("| Numerical time including baseline, study, and new directivity | %.3f s / %.0f s |", ...
    selected.studySeconds+selected.directivitySeconds, selected.budgetSeconds); ""; ...
    "Gain frequencies: 2.440, 2.445, 2.450, 2.455, 2.460 GHz. Broadside: azimuth 0, elevation 90 degrees."; ...
    "Direct S11 checks: 2.440, 2.450, 2.460 GHz. Both meshes passed interpolation validation; no direct-band fallback was needed."; ...
    "Mesh edge rules at 2.45 GHz: lambda/16 = 7.647767 mm; lambda/24 = 5.098511 mm."; ...
    "Directivity describes radiation concentration; it is distinct from realized gain, which includes radiation and mismatch losses."; ...
    "This is a two-mesh sensitivity check, not full convergence qualification. Gain conclusions are limited to the five sampled frequencies."; ...
    "All six screening candidates and the selected-candidate checks completed. No requirements were relaxed."; ...
    "The saved S11 and realized-gain results were reused. Only the selected antenna's 3D directivity was newly calculated."; ""];
writelines(checks, fullfile(outputFolder, "demo_checks.md"));
fprintf("Selected %s: worst S11 %.4f dB; minimum realized gain %.4f dBi.\n", ...
    config.candidate, fine.worstS11Db, fine.minGainDbi);
fprintf("Broadside directivity at 2.45 GHz: %.4f dBi; recorded directivity calculation %.3f s.\n", ...
    selected.broadsideDirectivityDbi, selected.directivitySeconds);
end

function figureHandle = selectedFigure(name, tag, position)
oldFigures = findall(groot, Type="figure", Tag=tag);
if ~isempty(oldFigures)
    close(oldFigures);
end
figureHandle = figure(Name=name, Tag=tag, Theme="light", Color="w", Position=position);
end

function saveView(figureHandle, outputFolder, name)
drawnow;
savefig(figureHandle, fullfile(outputFolder, name + ".fig"));
exportgraphics(figureHandle, fullfile(outputFolder, name + ".png"), Resolution=160);
end


function arrayStudy = runCoupledArrayStudy()
%RUNCOUPLEDARRAYSTUDY Coupled four-port D6 arrays, 3 spacings and 1 fine check.
%   Resume from array_results/array_study.mat. All fields use peak phasors.
%   AmplitudeTaper is terminal voltage, not incident-wave amplitude.

rootFolder = pwd();
outputFolder = fullfile(rootFolder, "array_results");
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
checkpoint = fullfile(outputFolder, "array_study.mat");
if isfile(checkpoint)
    saved = load(checkpoint, "arrayStudy");
    arrayStudy = saved.arrayStudy;
else
    saved = load(fullfile(rootFolder, "candidate_results", "study.mat"), "study");
    assert(saved.study.selectedVerified);
    elementConfig = saved.study.finalist.config;
    assert(abs(elementConfig.boardSide-0.1) < 1e-12);
    arrayStudy = struct("elementConfig", elementConfig, "frequencyHz", (2440:2460)*1e6, ...
        "gainFrequencyHz", [2440, 2450, 2460]*1e6, "referenceOhm", 50, ...
        "incidentWaves", 0.5*ones(4, 1), "totalIncidentW", 1, ...
        "radiusM", 100, "eta0", 376.730313668, "budgetSeconds", 600, ...
        "numericalSeconds", 0, "trials", {cell(1, 3)}, "selectedIndex", [], ...
        "fine", [], "patterns", [], "status", "screening", "verified", false, ...
        "callLog", {cell(0, 3)}, "created", string(datetime("now")), ...
        "matlabVersion", version, "error", "");
    spacings = [105, 112, 120]*1e-3;
    for index = 1:3
        arrayStudy.trials{index} = newArrayTrial(spacings(index), 16);
    end
    save(checkpoint, "arrayStudy", "-v7.3");
end

try
    for index = 1:3
        arrayStudy.trials{index} = evaluateTrial(arrayStudy.trials{index});
        trial = arrayStudy.trials{index};
        fprintf("Spacing %.0f mm: active reflection %.3f dB; min realized gain %.3f dBi; pass %d.\n", ...
            trial.spacingM*1e3, trial.worstActiveDb, trial.minGainDbi, trial.pass);
    end
    if isempty(arrayStudy.selectedIndex)
        passing = find(cellfun(@(trial) trial.pass, arrayStudy.trials));
        if isempty(passing)
            arrayStudy.status = "complete_no_passing_spacing";
            save(checkpoint, "arrayStudy", "-v7.3");
            return
        end
        bestGain = max(cellfun(@(trial) trial.minGainDbi, arrayStudy.trials(passing)));
        eligible = passing(cellfun(@(trial) trial.minGainDbi >= bestGain-0.5, arrayStudy.trials(passing)));
        [~, smallest] = min(cellfun(@(trial) trial.spacingM, arrayStudy.trials(eligible)));
        arrayStudy.selectedIndex = eligible(smallest);
        arrayStudy.fine = newArrayTrial(arrayStudy.trials{arrayStudy.selectedIndex}.spacingM, 24);
        save(checkpoint, "arrayStudy", "-v7.3");
    end
    arrayStudy.fine = evaluateTrial(arrayStudy.fine);
    arrayStudy.verified = arrayStudy.fine.pass;
    arrayStudy.status = "finalist_checked";
    save(checkpoint, "arrayStudy", "-v7.3");
    if isempty(arrayStudy.patterns)
        arrayStudy.patterns = evaluatePatterns(arrayStudy.fine);
    end
    arrayStudy.verified = arrayStudy.verified && arrayStudy.patterns.powerCheckPass;
    arrayStudy.status = "complete";
catch exception
    if strcmp(exception.identifier, "arrayDemo:Budget")
        arrayStudy.status = "budget_exhausted";
        fprintf("Soft numerical budget reached. Pending work is saved as incomplete.\n");
    else
        arrayStudy.status = "error";
        arrayStudy.error = string(getReport(exception, "extended", "hyperlinks", "off"));
        save(checkpoint, "arrayStudy", "-v7.3");
        rethrow(exception)
    end
end
save(checkpoint, "arrayStudy", "-v7.3");
fprintf("Array numerical time: %.2f / %.0f s; status %s.\n", ...
    arrayStudy.numericalSeconds, arrayStudy.budgetSeconds, arrayStudy.status);

    function trial = evaluateTrial(trial)
        if isempty(trial.array)
            elements = cell(1, 4);
            for elementIndex = 1:4
                elements{elementIndex} = makeD6Element(arrayStudy.elementConfig);
            end
            trial.positionsM = trial.spacingM/2*[-1, -1, 0; 1, -1, 0; -1, 1, 0; 1, 1, 0];
            trial.array = conformalArray(Element=elements, ElementPosition=trial.positionsM, ...
                Reference="origin", AmplitudeTaper=ones(1, 4), PhaseShift=zeros(1, 4));
            trial.gapM = trial.spacingM-arrayStudy.elementConfig.boardSide;
            trial.footprintSideM = trial.spacingM+arrayStudy.elementConfig.boardSide;
            assert(trial.gapM > 0, "Independent boards overlap.");
        end
        if isempty(trial.mesh)
            trial.mesh = timed(@() mesh(trial.array, MaxEdgeLength=299792458/2.45e9/trial.meshDivisor), ...
                trial, "fixed mesh");
            meshconfig(trial.array, "manual");
            trial.boardsSeparated = verifySeparateBoards(trial.mesh, trial.positionsM, arrayStudy.elementConfig.boardSide);
            assert(trial.boardsSeparated, "Array mesh bridges a gap between independent boards.");
            checkpointTrial(trial);
        end
        for frequencyIndex = 1:numel(arrayStudy.frequencyHz)
            if ~trial.sComplete(frequencyIndex)
                s = timed(@() sparameters(trial.array, arrayStudy.frequencyHz(frequencyIndex), ...
                    arrayStudy.referenceOhm, SweepOption="direct"), trial, "direct S " + frequencyIndex);
                trial.sMatrix(:, :, frequencyIndex) = s.Parameters;
                trial.sComplete(frequencyIndex) = true;
                checkpointTrial(trial);
            end
        end
        incident = arrayStudy.incidentWaves;
        for frequencyIndex = 1:numel(arrayStudy.frequencyHz)
            s = trial.sMatrix(:, :, frequencyIndex);
            trial.activeReflection(:, frequencyIndex) = (s*incident)./incident;
            trial.selfReflection(:, frequencyIndex) = diag(s);
            trial.reciprocityError(frequencyIndex) = max(abs(s-s.'), [], "all");
            trial.maxSingularValue(frequencyIndex) = max(svd(s));
            trial.acceptedPowerW(frequencyIndex) = sum(abs(incident).^2)-sum(abs(s*incident).^2);
        end
        trial.worstActiveDb = max(20*log10(abs(trial.activeReflection)), [], "all");
        offDiagonal = ~eye(4);
        allCoupling = reshape(trial.sMatrix, 16, []);
        trial.worstCouplingDb = max(20*log10(abs(allCoupling(offDiagonal(:), :))), [], "all");
        checkpointTrial(trial);

        for gainIndex = 1:3
            if isempty(trial.fieldChecks{gainIndex})
                frequency = arrayStudy.gainFrequencyHz(gainIndex);
                sIndex = find(arrayStudy.frequencyHz == frequency, 1);
                s = trial.sMatrix(:, :, sIndex);
                [voltage, expectedCurrent] = waveTerminals(s, incident, arrayStudy.referenceOhm);
                trial.array.AmplitudeTaper = abs(voltage).';
                trial.array.PhaseShift = rad2deg(angle(voltage)).';
                actualCurrent = timed(@() feedCurrent(trial.array, frequency), trial, "feed current " + gainIndex);
                actualCurrent = actualCurrent(:);
                currentError = norm(actualCurrent-expectedCurrent)/norm(expectedCurrent);
                terminalPower = 0.5*real(sum(voltage.*conj(actualCurrent)));
                recoveredIncident = (voltage+arrayStudy.referenceOhm*actualCurrent)/sqrt(8*arrayStudy.referenceOhm);
                incidentError = norm(recoveredIncident-incident)/norm(incident);
                powerError = abs(terminalPower-trial.acceptedPowerW(sIndex));
                assert(currentError < 1e-3 && incidentError < 1e-3 && powerError < 1e-3, ...
                    "Terminal-wave normalization check failed; inspect taper and feed-current conventions.");
                fields = timed(@() sampleFields(trial.array, frequency, [0; 0; arrayStudy.radiusM]), ...
                    trial, "broadside field " + gainIndex);
                intensity = radialIntensity(fields, [0; 0; 1], arrayStudy.radiusM);
                trial.gainDbi(gainIndex) = 10*log10(4*pi*intensity/arrayStudy.totalIncidentW);
                trial.fieldChecks{gainIndex} = struct("frequencyHz", frequency, ...
                    "voltagePeak", voltage, "currentPeakExpected", expectedCurrent, ...
                    "currentPeakActual", actualCurrent, "relativeCurrentError", currentError, ...
                    "relativeIncidentError", incidentError, "terminalPowerW", terminalPower, ...
                    "powerErrorW", powerError, "fields", fields);
                checkpointTrial(trial);
            end
        end
        trial.minGainDbi = min(trial.gainDbi);
        trial.valid = all(isfinite(trial.sMatrix), "all") && all(isfinite(trial.gainDbi)) && ...
            max(trial.reciprocityError) <= 1e-3 && max(trial.maxSingularValue) <= 1+1e-3 && ...
            all(trial.acceptedPowerW > 0) && trial.boardsSeparated;
        trial.pass = trial.valid && trial.worstActiveDb <= -10 && trial.minGainDbi >= 5;
        trial.complete = true;
        checkpointTrial(trial);
    end

    function patterns = evaluatePatterns(trial)
        frequency = arrayStudy.elementConfig.centerHz;
        sIndex = find(arrayStudy.frequencyHz == frequency, 1);
        [voltage, ~] = waveTerminals(trial.sMatrix(:, :, sIndex), arrayStudy.incidentWaves, 50);
        trial.array.AmplitudeTaper = abs(voltage).';
        trial.array.PhaseShift = rad2deg(angle(voltage)).';
        azimuth = -180:5:180;
        elevation = -90:5:90;
        [azimuthGrid, elevationGrid] = meshgrid(azimuth, elevation);
        directions = [cosd(elevationGrid(:)).*cosd(azimuthGrid(:)), ...
            cosd(elevationGrid(:)).*sind(azimuthGrid(:)), sind(elevationGrid(:))].';
        fields = timed(@() sampleFields(trial.array, frequency, arrayStudy.radiusM*directions), ...
            trial, "3D coupled fields");
        intensity = radialIntensity(fields, directions, arrayStudy.radiusM);
        intensityGrid = reshape(intensity, size(azimuthGrid));
        gainGrid = 10*log10(4*pi*max(intensityGrid, realmin)/arrayStudy.totalIncidentW);
        radiatedPower = trapz(deg2rad(elevation), ...
            trapz(deg2rad(azimuth), intensityGrid, 2).*cosd(elevation(:)));
        fieldsFarther = timed(@() sampleFields(trial.array, frequency, [0; 0; 2*arrayStudy.radiusM]), ...
            trial, "double-radius far-field check");
        fartherGain = 10*log10(4*pi*radialIntensity(fieldsFarther, [0; 0; 1], ...
            2*arrayStudy.radiusM)/arrayStudy.totalIncidentW);
        farFieldDeltaDb = fartherGain-trial.gainDbi(2);

        % Isolated-element reference: four independent radiators, no coupling.
        isolated = makeD6Element(arrayStudy.elementConfig);
        isolatedMesh = timed(@() mesh(isolated, MaxEdgeLength=299792458/frequency/24), ...
            trial, "isolated reference mesh");
        meshconfig(isolated, "manual");
        isolatedS = timed(@() sparameters(isolated, frequency, 50, SweepOption="direct"), ...
            trial, "isolated reference S");
        isolatedFields = timed(@() sampleFields(isolated, frequency, arrayStudy.radiusM*directions), ...
            trial, "isolated reference fields");
        isolatedVoltage = sqrt(2*50)*(0.5+isolatedS.Parameters(1)*0.5);
        translation = sum(exp(1i*2*pi*frequency/299792458*(trial.positionsM*directions)), 1);
        referenceFields = struct("E", isolatedFields.E.*(isolatedVoltage*translation), ...
            "H", isolatedFields.H.*(isolatedVoltage*translation));
        referenceIntensity = radialIntensity(referenceFields, directions, arrayStudy.radiusM);
        referenceGain = reshape(10*log10(4*pi*max(referenceIntensity, realmin)), size(azimuthGrid));
        % Independent check of E/H normalization at the isolated broadside.
        isolatedRealizedGain = timed(@() pattern(isolated, frequency, 0, 90, ...
            Type="realizedgain", Polarization="combined", Normalize=false, Termination=50), ...
            trial, "isolated reference normalization check");
        referenceBroadside = referenceGain(end, find(azimuth == 0, 1));
        normalizationDeltaDb = referenceBroadside-(isolatedRealizedGain+10*log10(4));
        patterns = struct("frequencyHz", frequency, "azimuthDeg", azimuth, ...
            "elevationDeg", elevation, "gainDbi", gainGrid, "fields", fields, ...
            "referenceGainDbi", referenceGain, "referenceFields", referenceFields, ...
            "isolatedElement", isolated, "isolatedMesh", isolatedMesh, ...
            "isolatedS", isolatedS, "isolatedRealizedGainDbi", isolatedRealizedGain, ...
            "normalizationDeltaDb", normalizationDeltaDb, "radiatedPowerW", radiatedPower, ...
            "acceptedPowerW", trial.acceptedPowerW(sIndex), "farFieldDeltaDb", farFieldDeltaDb, ...
            "powerCheckPass", radiatedPower > 0 && radiatedPower <= 1.02*trial.acceptedPowerW(sIndex) && ...
            abs(farFieldDeltaDb) <= 0.01 && abs(normalizationDeltaDb) <= 0.05);
        arrayStudy.patterns = patterns;
        checkpointTrial(trial);
    end

    function output = timed(operation, trial, label)
        if arrayStudy.numericalSeconds >= arrayStudy.budgetSeconds
            error("arrayDemo:Budget", "The numerical budget has been reached.");
        end
        timer = tic;
        try
            output = operation();
        catch exception
            elapsed = toc(timer);
            arrayStudy.numericalSeconds = arrayStudy.numericalSeconds+elapsed;
            arrayStudy.callLog(end+1, :) = {trial.spacingM*1e3, label+" FAILED", elapsed};
            save(checkpoint, "arrayStudy", "-v7.3");
            rethrow(exception)
        end
        elapsed = toc(timer);
        arrayStudy.numericalSeconds = arrayStudy.numericalSeconds+elapsed;
        arrayStudy.callLog(end+1, :) = {trial.spacingM*1e3, "lambda/"+trial.meshDivisor+" "+label, elapsed};
    end

    function checkpointTrial(trial)
        if trial.meshDivisor == 24
            arrayStudy.fine = trial;
        else
            trialIndex = find(abs([0.105, 0.112, 0.120]-trial.spacingM) < 1e-12, 1);
            arrayStudy.trials{trialIndex} = trial;
        end
        save(checkpoint, "arrayStudy", "-v7.3");
    end
end

function trial = newArrayTrial(spacing, divisor)
trial = struct("spacingM", spacing, "meshDivisor", divisor, "positionsM", [], ...
    "array", [], "mesh", [], "gapM", NaN, "footprintSideM", NaN, "boardsSeparated", false, ...
    "sMatrix", complex(nan(4, 4, 21)), "sComplete", false(1, 21), ...
    "activeReflection", complex(nan(4, 21)), "selfReflection", complex(nan(4, 21)), ...
    "reciprocityError", nan(1, 21), "maxSingularValue", nan(1, 21), ...
    "acceptedPowerW", nan(1, 21), "gainDbi", nan(1, 3), "fieldChecks", {cell(1, 3)}, ...
    "worstActiveDb", NaN, "worstCouplingDb", NaN, "minGainDbi", NaN, ...
    "complete", false, "valid", false, "pass", false);
end

function element = makeD6Element(config)
element = patchMicrostripInsetfed(Length=config.patchLength, Width=config.patchWidth, ...
    Height=config.height, GroundPlaneLength=config.boardSide, GroundPlaneWidth=config.boardSide, ...
    NotchLength=config.notchLength, NotchWidth=config.notchWidth, StripLineWidth=config.stripWidth, ...
    FeedOffset=[-config.boardSide/2, 0], PatchCenterOffset=[0, 0], ...
    Substrate=dielectric("Air"), Conductor=metal("Copper"), Tilt=0);
end

function separated = verifySeparateBoards(meshData, positions, side)
points = meshData.Points;
triangles = meshData.Triangles(1:3, :);
assigned = zeros(1, size(triangles, 2));
for board = 1:4
    inside = abs(points(1, :)-positions(board, 1)) <= side/2+1e-9 & ...
        abs(points(2, :)-positions(board, 2)) <= side/2+1e-9;
    assigned = assigned+all(inside(triangles), 1);
end
separated = all(assigned == 1);
end

function [voltage, current] = waveTerminals(s, incident, reference)
reflected = s*incident;
voltage = sqrt(2*reference)*(incident+reflected);
current = sqrt(2/reference)*(incident-reflected);
end

function fields = sampleFields(antenna, frequency, points)
[electric, magnetic] = EHfields(antenna, frequency, points);
fields = struct("E", electric, "H", magnetic);
end

function intensity = radialIntensity(fields, directions, radius)
% Peak-phasor time-average radial Poynting flux, converted to W/sr.
intensity = radius^2*0.5*real(sum(cross(fields.E, conj(fields.H), 1).*directions, 1));
end

function spacingTable = reportCoupledArrayStudy(arrayStudy)
%REPORTCOUPLEDARRAYSTUDY Plot and summarize saved coupled-array results.
%   No solver calls; arrays use 1 W total incident power at four 50-ohm ports.
outputFolder = fullfile(pwd(), "array_results");
if nargin < 1
    saved = load(fullfile(outputFolder, "array_study.mat"), "arrayStudy");
    arrayStudy = saved.arrayStudy;
end
values = nan(3, 7);
status = repmat("Incomplete", 3, 1);
rows = strings(3, 1);
for index = 1:3
    trial = arrayStudy.trials{index};
    selfDb = max(20*log10(abs(trial.selfReflection)), [], "all");
    values(index, :) = [trial.spacingM*1e3, trial.gapM*1e3, trial.footprintSideM*1e3, ...
        trial.worstActiveDb, selfDb, trial.worstCouplingDb, trial.minGainDbi];
    if trial.complete
        status(index) = "Fail";
        if trial.pass
            status(index) = "Pass";
        elseif ~trial.valid
            status(index) = "Numerically invalid";
        end
    end
    rows(index) = sprintf("| %.0f | %.0f | %.0f x %.0f | %.4f | %.4f | %.4f | %s |", ...
        values(index, 1), values(index, 2), values(index, 3), values(index, 3), ...
        values(index, 4), values(index, 6), values(index, 7), status(index));
end
spacingTable = array2table(values, VariableNames=["Spacing_mm", "Gap_mm", "FootprintSide_mm", ...
    "WorstActiveReflection_dB", "WorstSii_dB", "StrongestCoupling_dB", "MinRealizedGain_dBi"]);
spacingTable.Status = status;
writetable(spacingTable, fullfile(outputFolder, "spacing_comparison.csv"));
writetable(cell2table(arrayStudy.callLog, VariableNames=["Spacing_mm", "Operation", "Seconds"]), ...
    fullfile(outputFolder, "array_timing.csv"));
disp(spacingTable);

report = ["# Coupled 2x2 D6 array study"; ""; ...
    "Four independent 100 x 100 mm copper/air inset-fed patch boards, all identically oriented."; ...
    "D6 patch: 56.440519 x 55.063921 mm; air gap 3.059107 mm; original notch and strip dimensions retained."; ...
    "All four ports use 50-ohm reference impedance and equal, in-phase incident waves: a = [0.5;0.5;0.5;0.5] sqrt(W)."; ...
    "Total incident power is 1 W (0.25 W per port). Physical feed-network and connector losses are not modeled."; ...
    "Full 4x4 EM S-matrices were computed directly at 2.440:0.001:2.460 GHz, including mutual coupling."; ...
    "Active reflection is (S*a)_i/a_i. It is distinct from Sii, which assumes the other ports are matched."; ""; ...
    "## Screening results: fixed lambda/16 mesh"; ""; ...
    "| Spacing (mm) | Board gap (mm) | Footprint (mm) | Worst active reflection (dB) | Strongest coupling (dB) | Min broadside realized gain (dBi) | Status |"; ...
    "|---|---|---|---:|---:|---:|---|"; rows; ""; ...
    "Pass targets: active reflection <= -10 dB at every port/frequency, and realized gain >= 5 dBi at 2.440, 2.450, 2.460 GHz."; ...
    "No separate coupling limit was imposed. Gain is combined polarization at +z, referenced to total incident power."; ...
    "Selection: smallest passing spacing within 0.5 dB of the best minimum sampled gain among passing spacings."; ...
    "Study status: " + arrayStudy.status; ...
    sprintf("Numerical time: %.3f / %.0f seconds.", arrayStudy.numericalSeconds, arrayStudy.budgetSeconds); ""; ...
    "## Excitation and numerical checks"; ""; ...
    "The installed conformalArray implementation defines AmplitudeTaper in volts and uses a voltage source."; ...
    "Set terminal peak phasors V=sqrt(2*Z0)*(a+S*a) through AmplitudeTaper=abs(V), PhaseShift=angle(V)."; ...
    "Check feedCurrent against I=sqrt(2/Z0)*(a-S*a), recover a=(V+Z0*I)/sqrt(8*Z0), and compare terminal and wave power."; ...
    "Use Paccepted = ||a||^2-||S*a||^2 = 0.5*real(sum(V.*conj(I)))."; ...
    "Gain is calculated from the coupled E/H fields: G=4*pi*r^2*0.5*real((E cross conj(H)) dot rhat)/Pincident."; ...
    "Fields are sampled at 100 m. The planned doubled-distance check tests the selected center-frequency far-field estimate."; ...
    "Checks use max |S-S transpose| <= 0.001, largest singular value <= 1.001, relative current/incident-wave errors < 0.001, and power mismatch < 0.001 W."; ...
    "The array mesh is checked for triangles bridging the gaps; no shared ground panel is introduced."; ""];

diagnosticRows = strings(3, 1);
for index = 1:3
    trial = arrayStudy.trials{index};
    diagnosticRows(index) = sprintf("Spacing %.0f mm: %d/21 direct S samples; reciprocity error %.6g; max singular value %.6g.", ...
        trial.spacingM*1e3, nnz(trial.sComplete), max(trial.reciprocityError), max(trial.maxSingularValue));
end
report = [report; diagnosticRows];

%% Comparison charts use all completed samples, with missing values omitted.
comparisonFigure = figure(Name="Coupled array spacing comparison", Theme="light", ...
    Color="w", Position=[70, 70, 1240, 570]);
layout = tiledlayout(comparisonFigure, 1, 2, TileSpacing="compact", Padding="compact");
activeAxes = nexttile(layout);
gainAxes = nexttile(layout);
hold(activeAxes, "on");
hold(gainAxes, "on");
colors = lines(3);
for index = 1:3
    trial = arrayStudy.trials{index};
    label = sprintf("%.0f mm", trial.spacingM*1e3);
    plot(activeAxes, arrayStudy.frequencyHz/1e9, max(20*log10(abs(trial.activeReflection)), [], 1), ...
        LineWidth=1.7, Color=colors(index, :), DisplayName=label);
    plot(gainAxes, arrayStudy.gainFrequencyHz/1e9, trial.gainDbi, "-o", ...
        LineWidth=1.7, Color=colors(index, :), DisplayName=label);
end
yline(activeAxes, -10, "k--", "-10 dB target", LabelHorizontalAlignment="left", HandleVisibility="off");
yline(gainAxes, 5, "k--", "5 dBi target", LabelHorizontalAlignment="left", HandleVisibility="off");
ylim(activeAxes, [floor(min(values(:, 4)))-3, -9.5]);
xlim(activeAxes, [2.44, 2.46]);
xlim(gainAxes, [2.44, 2.46]);
grid(activeAxes, "on");
grid(gainAxes, "on");
xlabel(activeAxes, "Frequency (GHz)");
ylabel(activeAxes, "Worst-port active reflection (dB)");
xlabel(gainAxes, "Frequency (GHz)");
ylabel(gainAxes, "Broadside realized gain (dBi)");
legend(activeAxes, Location="best");
legend(gainAxes, Location="best");
title(activeAxes, "Equal incident waves: full coupled S-matrix");
title(gainAxes, "Three gain frequencies | 1 W total incident");
title(layout, "D6 coupled 2x2 array | Spacing comparison", FontSize=15);
saveArrayFigure(comparisonFigure, outputFolder, "array_spacing_comparison");

if ~isempty(arrayStudy.selectedIndex)
    coarse = arrayStudy.trials{arrayStudy.selectedIndex};
    hasFine = ~isempty(arrayStudy.fine) && arrayStudy.fine.complete;
    if hasFine
        fine = arrayStudy.fine;
    else
        fine = coarse;
    end
    currentErrors = cellfun(@(value) value.relativeCurrentError, fine.fieldChecks);
    incidentErrors = cellfun(@(value) value.relativeIncidentError, fine.fieldChecks);
    powerErrors = cellfun(@(value) value.powerErrorW, fine.fieldChecks);
    if hasFine
        report = [report; ""; "## Selected spacing and lambda/24 verification"; ""; ...
        sprintf("Selected spacing: %.0f mm in both x and y; gap %.0f mm; footprint %.0f x %.0f mm.", ...
        fine.spacingM*1e3, fine.gapM*1e3, fine.footprintSideM*1e3, fine.footprintSideM*1e3); ...
        sprintf("Verified result: %d. Fine-mesh active reflection %.6f dB; minimum gain %.6f dBi.", ...
        arrayStudy.verified, fine.worstActiveDb, fine.minGainDbi); ...
        sprintf("Fine-mesh strongest off-diagonal coupling: %.6f dB.", fine.worstCouplingDb); ...
        sprintf("Reciprocity error %.6g; maximum singular value %.6g.", ...
        max(fine.reciprocityError), max(fine.maxSingularValue)); ...
        sprintf("Max relative current error %.6g; incident-wave error %.6g; terminal/wave-power disagreement %.6g W.", ...
        max(currentErrors), max(incidentErrors), max(powerErrors)); ...
        sprintf("Worst active-reflection mesh change: %+.6f dB.", fine.worstActiveDb-coarse.worstActiveDb); ...
        sprintf("Minimum gain mesh change: %+.6f dB; largest gain sample change %.6f dB.", ...
        fine.minGainDbi-coarse.minGainDbi, max(abs(fine.gainDbi-coarse.gainDbi))); ...
        "This two-mesh comparison is a sensitivity check, not full convergence qualification."; ...
        "Gain conclusions apply at the sampled frequencies; the 3D pattern is at 2.45 GHz."; ""];
    else
        report = [report; ""; "## Provisional spacing recommendation"; ""; ...
            sprintf("Recommend %.0f mm center spacing in x and y from screening: %.0f mm board gaps and %.0f x %.0f mm footprint.", ...
            coarse.spacingM*1e3, coarse.gapM*1e3, coarse.footprintSideM*1e3, coarse.footprintSideM*1e3); ...
            sprintf("Minimum sampled gain %.6f dBi, within %.6f dB of the best screening result.", ...
            coarse.minGainDbi, max(values(:, 7))-coarse.minGainDbi); ...
            sprintf("Max relative current error %.6g; incident-wave error %.6g; terminal/wave-power disagreement %.6g W.", ...
            max(currentErrors), max(incidentErrors), max(powerErrors)); ...
            sprintf("Finer-mesh verification is incomplete: %d/21 direct S samples and %d/3 gain samples saved.", ...
            nnz(arrayStudy.fine.sComplete), nnz(isfinite(arrayStudy.fine.gainDbi))); ...
            "The partial finer-mesh results are preserved in array_study.mat and are not reported as a complete pass."; ...
            "The active-match, coupling and gain figures use the completed lambda/16 screening results."; ...
            "A solver call overran the soft numerical budget. No additional solver calls were started afterward."; ...
            sprintf("Longest recorded solver-call elapsed interval: %.3f seconds. This is wall-clock time, not CPU-only time.", ...
            max(cell2mat(arrayStudy.callLog(:, 3)))); ""];
    end
    activeTable = array2table([arrayStudy.frequencyHz(:)/1e9, ...
        20*log10(abs(fine.activeReflection)).', 20*log10(abs(fine.selfReflection)).'], ...
        VariableNames=["Frequency_GHz", "Active1_dB", "Active2_dB", "Active3_dB", "Active4_dB", ...
        "S11_dB", "S22_dB", "S33_dB", "S44_dB"]);
    writetable(activeTable, fullfile(outputFolder, "selected_active_and_self.csv"));
    if hasFine
        writetable(table(arrayStudy.gainFrequencyHz(:)/1e9, coarse.gainDbi(:), fine.gainDbi(:), ...
        VariableNames=["Frequency_GHz", "Lambda16Gain_dBi", "Lambda24Gain_dBi"]), ...
        fullfile(outputFolder, "array_mesh_gain.csv"));
    end

    geometryFigure = figure(Name="Selected coupled array geometry", Theme="light", ...
        Color="w", Position=[90, 90, 1050, 760]);
    show(fine.array);
    view(35, 30);
    sgtitle(geometryFigure, {sprintf("D6 coupled 2x2 | %.0f mm center spacing", fine.spacingM*1e3), ...
        sprintf("Four separate 100 mm boards | %.0f mm gaps | %.0f x %.0f mm footprint", ...
        fine.gapM*1e3, fine.footprintSideM*1e3, fine.footprintSideM*1e3)}, FontSize=14, FontWeight="bold");
    saveArrayFigure(geometryFigure, outputFolder, "array_geometry");

    portFigure = figure(Name="Selected array coupling and matching", Theme="light", ...
        Color="w", Position=[100, 100, 1400, 540]);
    layout = tiledlayout(portFigure, 1, 3, TileSpacing="compact", Padding="compact");
    portAxes = nexttile(layout);
    plot(portAxes, arrayStudy.frequencyHz/1e9, 20*log10(abs(fine.activeReflection)).', LineWidth=1.5);
    yline(portAxes, -10, "k--", HandleVisibility="off");
    title(portAxes, "Active reflection: all ports driven");
    ylabel(portAxes, "|(S a)_i / a_i| (dB)");
    legend(portAxes, "Port 1", "Port 2", "Port 3", "Port 4", Location="best");
    selfAxes = nexttile(layout);
    plot(selfAxes, arrayStudy.frequencyHz/1e9, 20*log10(abs(fine.selfReflection)).', LineWidth=1.5);
    title(selfAxes, "Sii: other ports matched");
    ylabel(selfAxes, "|S_{ii}| (dB)");
    legend(selfAxes, "S11", "S22", "S33", "S44", Location="best");
    couplingAxes = nexttile(layout);
    hold(couplingAxes, "on");
    pairs = nchoosek(1:4, 2);
    couplingValues = nan(21, 6);
    couplingLabels = strings(1, 6);
    for index = 1:6
        couplingValues(:, index) = 20*log10(abs(reshape(fine.sMatrix(pairs(index, 1), pairs(index, 2), :), [], 1)));
        couplingLabels(index) = "S"+pairs(index, 1)+pairs(index, 2);
        plot(couplingAxes, arrayStudy.frequencyHz/1e9, couplingValues(:, index), ...
            LineWidth=1.5, DisplayName=couplingLabels(index));
    end
    title(couplingAxes, "Mutual coupling: distinct port pairs");
    ylabel(couplingAxes, "|S_{ij}| (dB), i \neq j");
    legend(couplingAxes, Location="best");
    for axesHandle = [portAxes, selfAxes, couplingAxes]
        grid(axesHandle, "on");
        xlabel(axesHandle, "Frequency (GHz)");
        xlim(axesHandle, [2.44, 2.46]);
    end
    title(layout, sprintf("Selected %.0f mm spacing | Direct four-port EM results | \\lambda/%d", ...
        fine.spacingM*1e3, fine.meshDivisor), FontSize=15);
    saveArrayFigure(portFigure, outputFolder, "array_port_curves");
    writetable(array2table([arrayStudy.frequencyHz(:)/1e9, couplingValues], ...
        VariableNames=["Frequency_GHz", couplingLabels]), fullfile(outputFolder, "selected_coupling_dB.csv"));
end

if ~isempty(arrayStudy.patterns)
    patterns = arrayStudy.patterns;
    report = [report; "## Power and pattern checks at 2.45 GHz"; ""; ...
        sprintf("Incident power: 1 W; accepted power %.8f W; integrated radiated power %.8f W.", ...
        patterns.acceptedPowerW, patterns.radiatedPowerW); ...
        sprintf("Far-field gain change at twice the distance: %+.6g dB (limit 0.01 dB).", patterns.farFieldDeltaDb); ...
        sprintf("Isolated-reference normalization check: %+.6g dB (limit 0.05 dB).", patterns.normalizationDeltaDb); ...
        sprintf("Power/pattern check passed: %d. Sphere integration uses 5-degree samples with sin(theta) weighting.", patterns.powerCheckPass); ...
        "The isolated reference is the translated sum of four independent element fields at 0.25 W incident per element."; ...
        "The coupled result uses the complete array EM fields. The isolated reference is explicitly uncoupled."; ...
        "3D display clips values more than 35 dB below the sampled peak; the saved numerical data is unmodified."; ""];
    patternFigure = figure(Name="Coupled array 3D realized gain", Theme="light", ...
        Color="w", Position=[130, 100, 1050, 800]);
    displayGain = max(patterns.gainDbi, max(patterns.gainDbi, [], "all")-35);
    patternCustom(flipud(displayGain).', 90-fliplr(patterns.elevationDeg), patterns.azimuthDeg);
    sgtitle(patternFigure, {sprintf("Coupled D6 2x2 | %.0f mm spacing | 2.450 GHz", arrayStudy.fine.spacingM*1e3), ...
        sprintf("Realized gain (dBi) | 1 W total incident | Broadside %.2f dBi", arrayStudy.fine.gainDbi(2))}, ...
        FontSize=15, FontWeight="bold");
    bars = findall(patternFigure, Type="colorbar");
    for index = 1:numel(bars)
        bars(index).Label.String = "Realized gain (dBi)";
    end
    saveArrayFigure(patternFigure, outputFolder, "array_realized_gain_3d");

    referenceFigure = figure(Name="Coupled versus isolated reference", Theme="light", ...
        Color="w", Position=[150, 120, 1150, 550]);
    layout = tiledlayout(referenceFigure, 1, 2, TileSpacing="compact", Padding="compact");
    for index = 1:2
        azimuth = (index-1)*90;
        azimuthIndex = find(patterns.azimuthDeg == azimuth, 1);
        axesHandle = nexttile(layout);
        plot(axesHandle, patterns.elevationDeg, patterns.gainDbi(:, azimuthIndex), "-", ...
            patterns.elevationDeg, patterns.referenceGainDbi(:, azimuthIndex), "--", LineWidth=1.6);
        xlabel(axesHandle, "Elevation (degrees)");
        ylabel(axesHandle, "Realized gain (dBi), 1 W total incident");
        title(axesHandle, sprintf("Azimuth %.0f degrees", azimuth));
        grid(axesHandle, "on");
        xlim(axesHandle, [-90, 90]);
        legend(axesHandle, "Coupled EM array", "Four isolated elements (reference)", Location="best");
    end
    title(layout, "2.450 GHz | Coupling effect at equal total incident power", FontSize=15);
    saveArrayFigure(referenceFigure, outputFolder, "coupled_vs_isolated");
else
    report = [report; ""; "## Pending pattern checks"; ""; ...
        "The coupled 3D realized-gain pattern, isolated-element pattern comparison, integrated radiated-power check,"; ...
        "and doubled-distance far-field check remain pending because the numerical budget was exhausted."; ...
        "The saved broadside gains are the actual full coupled E/H field calculations, not an ideal array-factor estimate."; ""];
end
writelines(report, fullfile(outputFolder, "array_summary.md"));
end

function saveArrayFigure(figureHandle, outputFolder, name)
drawnow;
savefig(figureHandle, fullfile(outputFolder, name+".fig"));
exportgraphics(figureHandle, fullfile(outputFolder, name+".png"), Resolution=150);
end
