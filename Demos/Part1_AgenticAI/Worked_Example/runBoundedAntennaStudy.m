function study = runBoundedAntennaStudy()
%RUNBOUNDEDANTENNASTUDY Execute/resume the six-candidate, 180 s experiment.
%   Reuses this session's baseline. Checkpoints are saved after every call.
%   Repeated calls resume missing work rather than repeating completed solves.

rootFolder = fileparts(mfilename("fullpath"));
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
