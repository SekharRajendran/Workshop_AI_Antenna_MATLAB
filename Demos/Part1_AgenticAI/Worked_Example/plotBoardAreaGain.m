function figureHandle = plotBoardAreaGain()
%PLOTBOARDAREAGAIN Plot cached screening data; no antenna solves are performed.
%   Worst-band gain is the minimum over the five specified gain frequencies.

outputFolder = fullfile(fileparts(mfilename("fullpath")), "candidate_results");
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
