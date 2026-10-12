function arrayStudy = runCoupledArrayStudy()
%RUNCOUPLEDARRAYSTUDY Coupled four-port D6 arrays, 3 spacings and 1 fine check.
%   Resume from array_results/array_study.mat. All fields use peak phasors.
%   AmplitudeTaper is terminal voltage, not incident-wave amplitude.

rootFolder = fileparts(mfilename("fullpath"));
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
