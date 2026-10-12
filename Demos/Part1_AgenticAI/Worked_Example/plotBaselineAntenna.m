function figures = plotBaselineAntenna(baseline)
%PLOTBASELINEANTENNA Show/export saved baseline results without EM solves.
%   plotBaselineAntenna() loads baseline_results/baseline.mat.

outputFolder = fullfile(fileparts(mfilename("fullpath")), "baseline_results");
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
