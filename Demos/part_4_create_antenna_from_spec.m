%[text] # Part 4: Create Antenna from Excel Specification
%[text] This script reads `Part_4_Antenna_Spec.xlsx`, synthesizes the requested
%[text] inset-fed microstrip patch antenna, and runs the requested visual checks.

clear
clc

specFile = "Part_4_Antenna_Spec.xlsx";

specTable = readtable(specFile,Sheet="AntennaSpec",TextType="string");
analysisPlan = readtable(specFile,Sheet="AnalysisPlan",TextType="string");
acceptanceCriteria = readtable(specFile,Sheet="AcceptanceCriteria",TextType="string");

spec = localParseSpec(specTable);
localValidateRequiredSpec(specTable,specFile)

f0 = spec.OperatingFrequencyGHz*1e9;
freq = linspace(spec.FrequencyStartGHz,spec.FrequencyStopGHz, ...
    spec.FrequencyPoints)*1e9;
z0 = spec.PortImpedanceOhm;

fprintf("Loaded %s spec version %s\n",specFile,spec.SpecVersion)
fprintf("Antenna: %s, %s\n",spec.AntennaTechnology,spec.AntennaType)
fprintf("Operating frequency: %.3f GHz\n",f0/1e9)
fprintf("Frequency sweep: %.3f to %.3f GHz, %d points\n", ...
    freq(1)/1e9,freq(end)/1e9,numel(freq))

%% Create antenna
conductor = metal(spec.ConductorMaterial);
substrate = dielectric(spec.SubstrateMaterial);

template = patchMicrostripInsetfed(Substrate=substrate,Conductor=conductor);
ant = design(template,f0);

pcb = pcbStack(ant);
pcb.Name = "Part 4 Inset-Fed Microstrip Patch";

lambda0 = physconst("lightspeed")/f0;
meshMaxEdgeLength = spec.MeshMaxEdgeWavelengthFraction*lambda0;

fabrication = struct( ...
    ConnectorType=spec.ConnectorType, ...
    ConnectorImpedanceOhm=spec.ConnectorImpedanceOhm, ...
    ConnectorPreferredManufacturer=spec.ConnectorPreferredManufacturer, ...
    ConnectorMountingEdge=spec.ConnectorMountingEdge, ...
    FabricationSubstrateMaterial=spec.FabricationSubstrateMaterial);

designSummary = table( ...
    f0/1e9,ant.Length*1e3,ant.Width*1e3,ant.Height*1e3, ...
    ant.GroundPlaneLength*1e3,ant.GroundPlaneWidth*1e3, ...
    z0,meshMaxEdgeLength*1e3, ...
    VariableNames=["Frequency_GHz","PatchLength_mm","PatchWidth_mm", ...
    "SubstrateHeight_mm","GroundLength_mm","GroundWidth_mm", ...
    "ReferenceImpedance_ohm","MeshMaxEdgeLength_mm"]);

disp(designSummary)
disp("Fabrication metadata:")
disp(fabrication)

%% Visual checks requested in the workbook
sparams = [];
s11dB = [];

if spec.PlotGeometry
    figure(Name="Part 4 Antenna Geometry")
    show(ant)
    title("Inset-Fed Microstrip Patch at " + spec.OperatingFrequencyGHz + " GHz")
end

if spec.PlotMesh
    figure(Name="Part 4 Antenna Mesh")
    mesh(ant,MaxEdgeLength=meshMaxEdgeLength)
    title("Mesh, Max Edge Length = " + round(meshMaxEdgeLength*1e3,2) + " mm")
end

if spec.PlotRadiationPattern
    figure(Name="Part 4 Radiation Pattern")
    pattern(ant,f0)
    title("Radiation Pattern at " + spec.OperatingFrequencyGHz + " GHz")
end

if spec.PlotCurrent
    figure(Name="Part 4 Surface Current")
    current(ant,f0,Scale=spec.CurrentScale)
    title("Surface Current at " + spec.OperatingFrequencyGHz + " GHz")
end

if spec.PlotSParameters
    sweepOption = localSweepOption(spec.SParameterSweepMethod);
    if sweepOption == ""
        sparams = sparameters(ant,freq,z0);
    else
        sparams = sparameters(ant,freq,z0,SweepOption=sweepOption);
    end

    s11dB = 20*log10(abs(squeeze(sparams.Parameters(1,1,:))));
    [minS11dB,minIdx] = min(s11dB);
    s11AtF0dB = interp1(freq,s11dB,f0,"linear");

    figure(Name="Part 4 S11")
    plot(freq/1e9,s11dB,LineWidth=1.5)
    hold on
    yline(spec.ReturnLossTargetdB,"--","Return-loss target")
    xline(f0/1e9,":","Operating frequency")
    hold off
    grid on
    xlabel("Frequency (GHz)")
    ylabel("|S_{11}| (dB)")
    title("Input Match, " + string(z0) + "-ohm Reference")

    fprintf("Minimum S11: %.2f dB at %.3f GHz\n",minS11dB,freq(minIdx)/1e9)
    fprintf("Interpolated S11 at %.3f GHz: %.2f dB\n",f0/1e9,s11AtF0dB)
    fprintf("Return-loss target near f0: S11 <= %.2f dB\n", ...
        spec.ReturnLossTargetdB)
end

%% Save reusable design data
save("part_4_antenna_from_spec.mat","spec","specTable","analysisPlan", ...
    "acceptanceCriteria","ant","pcb","designSummary","fabrication", ...
    "freq","z0","meshMaxEdgeLength","sparams","s11dB")

disp("Created variables: spec, ant, pcb, designSummary, fabrication, freq, sparams, s11dB")
disp("Saved part_4_antenna_from_spec.mat")

function spec = localParseSpec(specTable)
spec = struct;
for idx = 1:height(specTable)
    key = matlab.lang.makeValidName(strtrim(specTable.Key(idx)));
    dataType = lower(strtrim(specTable.DataType(idx)));
    valueText = strtrim(specTable.ValueText(idx));

    switch dataType
        case "double"
            value = str2double(valueText);
            if isnan(value)
                error("Invalid numeric value for key '%s': %s",key,valueText)
            end
        case "logical"
            value = any(strcmpi(valueText,["true","1","yes"]));
        otherwise
            value = string(valueText);
    end

    spec.(key) = value;
end
end

function localValidateRequiredSpec(specTable,specFile)
requiredText = lower(strtrim(string(specTable.Required)));
required = ismember(requiredText,["true","1","yes"]);
missingValue = ismissing(specTable.ValueText) | ...
    strlength(strtrim(string(specTable.ValueText))) == 0;
missingRequired = required & missingValue;
if any(missingRequired)
    missingKeys = strjoin(specTable.Key(missingRequired),", ");
    error("Required keys missing in %s: %s",specFile,missingKeys)
end
end

function sweepOption = localSweepOption(method)
method = lower(strtrim(string(method)));
if contains(method,"grad")
    sweepOption = "interpWithGrad";
elseif contains(method,"interp")
    sweepOption = "interp";
else
    sweepOption = "";
end
end
