function [feedCandidates, feedPlan] = planArrayFeedCandidates
%PLANARRAYFEEDCANDIDATES Create six planned array/feed candidates, without EM.
%   [feedCandidates,feedPlan] = planArrayFeedCandidates creates a MATLAB
%   table and RF PCB Toolbox microstripLine starting geometries. It reads
%   this session's completed array screening CSV. It does NOT evaluate feed
%   S-parameters, loaded gain, or resume the unfinished array verification.
%   Outputs are saved in feed_plan next to this function.

rootFolder = fileparts(mfilename('fullpath'));
outputFolder = fullfile(rootFolder,'feed_plan');
if ~isfolder(outputFolder)
    mkdir(outputFolder);
end
arrayScreening = readtable(fullfile(rootFolder,'array_results', ...
    'spacing_comparison.csv'),TextType='string');

feedPlan.CenterFrequency_Hz = 2.45e9;
feedPlan.Frequencies_Hz = (2440:2460)*1e6;
feedPlan.ReferenceImpedance_ohm = 50;
feedPlan.Goals = struct('InputReferencedGain_dBi',14, ...
    'InputS11_dB',-10,'AmplitudeSpread_dB',0.5, ...
    'PhaseSpread_deg',5,'MatchedLoadDeliveryLoss_dB',0.75);
feedPlan.GoalStatus = "Proposed; no feed candidate has been evaluated";
feedPlan.Radiator = "Four unchanged D6 100 mm copper/air boards";
feedPlan.AntennaPortOrder = [-1 -1 0; 1 -1 0; -1 1 0; 1 1 0];
feedPlan.PositionRule = "positions = spacing_m/2 * AntennaPortOrder";
feedPlan.ArrayDataStatus = ...
    "lambda/16 screening complete; selected lambda/24 checks incomplete";
feedPlan.Connection = "Separate module, four equal 300 mm nominal 50-ohm " + ...
    "coax jumpers, transition to existing D6 board-edge ports; " + ...
    "placement and cable reach require layout verification";
feedPlan.ReuseCondition = "Existing antenna S is a provisional network " + ...
    "load only when ports/boards stay unchanged and added structure " + ...
    "scattering/common-mode currents can be neglected or validated";

% Explicit modeling assumptions, not certified laminate specifications.
materialName = ["LowLossAssumed"; "FR4Assumed"];
epsilonR = [3.55; 4.30];
lossTangent = [0.0027; 0.020];
height_mm = [0.813; 0.813];
feedPlan.Materials = table(materialName,epsilonR,lossTangent,height_mm);
feedPlan.MaterialNote = "Replace assumed Dk/Df with the selected laminate's " + ...
    "design values and fabrication data; radiator substrate remains air";
feedPlan.CopperThickness_m = 35e-6;
feedPlan.CopperConductivity_Spm = 5.96e7;

% Geometry synthesis only: design() sizes a cross section and electrical
% length. These are straight line templates, not an assembled feed layout.
width50_mm = zeros(2,1);
width70_mm = zeros(2,1);
quarter70_mm = zeros(2,1);
for materialIndex = 1:2
    substrate = dielectric(Name=materialName(materialIndex), ...
        EpsilonR=epsilonR(materialIndex), ...
        LossTangent=lossTangent(materialIndex), ...
        Thickness=height_mm(materialIndex)*1e-3);
    copper = metal(Name='FeedCopper', ...
        Conductivity=feedPlan.CopperConductivity_Spm, ...
        Thickness=feedPlan.CopperThickness_m);
    lineSeed = microstripLine;
    lineSeed.Substrate = substrate;
    lineSeed.Height = height_mm(materialIndex)*1e-3;
    lineSeed.Conductor = copper;
    line50 = design(lineSeed,feedPlan.CenterFrequency_Hz,Z0=50);
    line70 = design(lineSeed,feedPlan.CenterFrequency_Hz, ...
        Z0=50*sqrt(2),LineLength=0.25);
    assert(abs(line50.Height-height_mm(materialIndex)*1e-3)<1e-10 && ...
        abs(line70.Height-height_mm(materialIndex)*1e-3)<1e-10, ...
        'Line synthesis changed the proposed substrate height.');
    line50.Length = 10e-3; % Common input-line template; routes below set length.
    width50_mm(materialIndex) = line50.Width*1e3;
    width70_mm(materialIndex) = line70.Width*1e3;
    quarter70_mm(materialIndex) = line70.Length*1e3;
    feedPlan.LineTemplates(materialIndex).Material = materialName(materialIndex);
    feedPlan.LineTemplates(materialIndex).Line50 = line50;
    feedPlan.LineTemplates(materialIndex).QuarterWave70 = line70;
end
feedPlan.LineDimensions = table(materialName,width50_mm,width70_mm, ...
    quarter70_mm);
feedPlan.LineDimensionStatus = ...
    "Initial synthesized dimensions; discontinuities and loss unverified";

ID = "F" + string((1:6)');
TestOrder = [1;3;4;2;5;6];
Spacing_mm = [105;105;105;105;112;120];
ArrayOutlineSide_mm = Spacing_mm + 100;
materialIndex = [1;2;1;1;1;1];
FeedSubstrate = materialName(materialIndex);
Divider = ["Wilkinson";"Wilkinson";"Matched tee"; ...
    "Wilkinson";"Wilkinson";"Wilkinson"];
Route = ["Standard";"Standard";"Standard";"Short";"Short";"Short"];
% Per source-to-element path: input + one interstage + one final branch.
% Total includes splitter 50-ohm port lines when the layout is assembled.
Input50_mm = 10*ones(6,1);
Interstage50_mm = [30;30;30;15;15;15];
Output50_mm = [60;60;60;35;35;35];
Total50PerPath_mm = Input50_mm + Interstage50_mm + Output50_mm;
CoaxPerOutput_mm = 300*ones(6,1);
Width50_mm = width50_mm(materialIndex);
Width70_mm = width70_mm(materialIndex);
Quarter70_mm = quarter70_mm(materialIndex);
Purpose = ["Reference";"Isolate feed laminate effect versus F1"; ...
    "Isolate divider topology versus F1"; ...
    "Reduce equal-length routing versus F1"; ...
    "Compare spacing against F4";"Compare spacing against F4"];
[found,sourceRow] = ismember(Spacing_mm,arrayScreening.Spacing_mm);
assert(all(found),'Missing completed array screening result.');
AntennaOnlyMinGain_dBi = arrayScreening.MinRealizedGain_dBi(sourceRow);
AntennaOnlyMargin_dB = AntennaOnlyMinGain_dBi - ...
    feedPlan.Goals.InputReferencedGain_dBi;
LoadedGain_dBi = NaN(6,1);
Status = repmat("Planned",6,1);
feedCandidates = table(ID,TestOrder,Spacing_mm,ArrayOutlineSide_mm, ...
    FeedSubstrate,Divider,Route,Input50_mm,Interstage50_mm,Output50_mm, ...
    Total50PerPath_mm,CoaxPerOutput_mm,Width50_mm,Width70_mm,Quarter70_mm, ...
    AntennaOnlyMinGain_dBi,AntennaOnlyMargin_dB,LoadedGain_dBi,Status,Purpose);
feedPlan.Candidates = feedCandidates;
feedPlan.SplitterCount = 3;
feedPlan.SplitterLevels = 2;
feedPlan.WilkinsonIsolationResistance_ohm = 100;
feedPlan.RouteNote = "50-ohm lengths are layout targets; exclude the " + ...
    "two quarter-wave transformer arms traversed per path, coax and " + ...
    "connectors. Include catalog splitter port lines once, within these " + ...
    "targets. Do not duplicate the D6 inset strip.";
feedPlan.PhaseNote = "Equal total electrical delay through both splitter " + ...
    "stages, PCB routes, cables and launches; check loaded antenna waves.";
feedPlan.ProposedNumericalBudget_s = 600;
feedPlan.BudgetNote = "New proposed feed-study soft budget, not started. " + ...
    "Finish in-flight call, checkpoint and stop. Previous array budget " + ...
    "remains exhausted; completion of its checks needs a separate stage.";

writetable(feedCandidates,fullfile(outputFolder,'feed_candidates.csv'));
writetable(feedPlan.LineDimensions,fullfile(outputFolder,'line_dimensions.csv'));
save(fullfile(outputFolder,'feed_plan.mat'),'feedCandidates','feedPlan');
disp(feedCandidates(:,{'ID','TestOrder','Spacing_mm','FeedSubstrate', ...
    'Divider','Total50PerPath_mm','AntennaOnlyMargin_dB','Status'}));
disp(feedPlan.LineDimensions);
fprintf('Planning only: no feed S-parameters or loaded gain evaluated.\n');
end
