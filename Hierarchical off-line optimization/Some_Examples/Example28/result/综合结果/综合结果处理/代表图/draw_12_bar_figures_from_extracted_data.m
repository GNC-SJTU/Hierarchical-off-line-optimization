%% draw_12_bar_figures_equal_bar_width_top_tick.m
% Draw 12 separated bar figures from extracted Fig. 12 data.
%
% Key features:
%   1) Use extracted values and colors from:
%        Fig12_extracted_segmented_data_with_colors.mat
%
%   2) Use formatting templates:
%        通信消耗_新.fig  -> CommunicationCost
%        算力消耗_新.fig  -> ComputationCost
%        精度_新.fig      -> AccuracyMetric
%
%   3) Use the same Y-axis limits and ticks for the same metric
%      across Low, Medium, High, and Very High requirements.
%
%   4) Put legend inside the axes.
%
%   5) Bars belonging to the same UAV are touching each other.
%
%   6) Every single bar has the same width in all 12 figures.
%      Requirements with fewer steps naturally have larger gaps between UAV groups.
%
%   7) The upper end of each Y-axis is always labeled with a tick value.

clear; clc; close all;

%% Load extracted data

matFile = 'Fig12_extracted_segmented_data_with_colors.mat';

if ~isfile(matFile)
    error('Cannot find %s. Please run the extraction script first.', matFile);
end

load(matFile, ...
    'Grouped', ...
    'reqNames', ...
    'reqLabels', ...
    'uavLabels');

%% Output folder

outDir = fullfile(pwd, 'Fig12_12_separate_bar_figures_equal_bar_width_top_tick');

if ~exist(outDir, 'dir')
    mkdir(outDir);
end

%% Template files

templateComm = '通信消耗_新.fig';
templateComp = '算力消耗_新.fig';
templateAcc  = '精度_新.fig';

if ~isfile(templateComm)
    error('Cannot find communication template: %s', templateComm);
end

if ~isfile(templateComp)
    error('Cannot find computation template: %s', templateComp);
end

if ~isfile(templateAcc)
    error('Cannot find accuracy template: %s', templateAcc);
end

%% Legend setting

legendInsideLocation    = 'northeast';
legendInsideOrientation = 'vertical';
legendInsideBox         = 'off';

%% Bar width setting
% Every individual bar has exactly the same width in all 12 figures.
%
% Recommended:
%   0.18 -> Very High: 5 bars x 0.18 = 0.90 group width
%           High:      4 bars x 0.18 = 0.72 group width
%           Medium:    3 bars x 0.18 = 0.54 group width
%           Low:       2 bars x 0.18 = 0.36 group width
%
% Thus, requirements with fewer steps naturally have larger gaps between UAV groups.

singleBarWidth = 0.18;

%% Metric settings

metricList = struct([]);

metricList(1).fieldName  = 'CommunicationCost';
metricList(1).colorField = 'CommunicationCostStepColors';
metricList(1).titleText  = 'Communication Cost';
metricList(1).yLabelText = 'Communication Cost';
metricList(1).fileTag    = 'CommunicationCost';
metricList(1).template   = templateComm;

metricList(2).fieldName  = 'ComputationCost';
metricList(2).colorField = 'ComputationCostStepColors';
metricList(2).titleText  = 'Computation Cost';
metricList(2).yLabelText = 'Computation Cost';
metricList(2).fileTag    = 'ComputationCost';
metricList(2).template   = templateComp;

metricList(3).fieldName  = 'AccuracyMetric';
metricList(3).colorField = 'AccuracyMetricStepColors';
metricList(3).titleText  = 'Accuracy Metric tr(P)';
metricList(3).yLabelText = 'Accuracy Metric tr(P)';
metricList(3).fileTag    = 'AccuracyMetric';
metricList(3).template   = templateAcc;

%% Read template styles

for m = 1:numel(metricList)
    metricList(m).style = read_template_style(metricList(m).template);
end

%% Compute unified Y-axis limits and ticks for each metric

for m = 1:numel(metricList)

    metricField = metricList(m).fieldName;
    style = metricList(m).style;

    allValues = [];

    for r = 1:numel(reqNames)
        reqField = reqNames{r};
        nStep = Grouped.(reqField).AvailableStepCount;

        Y = Grouped.(reqField).(metricField);
        Y = Y(:, 1:nStep);

        allValues = [allValues; Y(:)]; %#ok<AGROW>
    end

    allValues = allValues(~isnan(allValues));

    [globalYLim, globalYTick] = make_global_y_axis(values_for_axis(allValues, style), style);

    % Force the top end of the Y-axis to appear as a labeled tick.
    globalYTick = force_top_y_tick(globalYTick, globalYLim);

    metricList(m).globalYLim  = globalYLim;
    metricList(m).globalYTick = globalYTick;
end

%% Draw 12 figures

for r = 1:numel(reqNames)

    reqField = reqNames{r};
    reqLabel = reqLabels{r};

    nStep = Grouped.(reqField).AvailableStepCount;
    stepLabels = arrayfun(@(k) sprintf('Step %d', k), ...
        1:nStep, 'UniformOutput', false);

    for m = 1:numel(metricList)

        metricField = metricList(m).fieldName;
        colorField  = metricList(m).colorField;
        style       = metricList(m).style;

        Y = Grouped.(reqField).(metricField);
        Y = Y(:, 1:nStep);

        stepColors = Grouped.(reqField).(colorField);
        stepColors = stepColors(1:nStep, :);

        % For log-scale plots, non-positive values cannot be displayed.
        % Original data are not modified.
        Yplot = Y;
        if strcmpi(style.YScale, 'log')
            invalidMask = Yplot <= 0 & ~isnan(Yplot);
            if any(invalidMask(:))
                warning('%s - %s contains non-positive values; these bars are hidden on log scale.', ...
                    reqLabel, metricField);
                Yplot(invalidMask) = NaN;
            end
        end

        %% Create figure using template size

        fig = figure( ...
            'Color', style.FigureColor, ...
            'Units', style.FigureUnits, ...
            'Position', style.FigurePosition, ...
            'PaperUnits', style.PaperUnits, ...
            'PaperPosition', style.PaperPosition);

        ax = axes(fig);
        hold(ax, 'on');

        set(ax, 'Units', style.AxesUnits);
        set(ax, 'Position', style.AxesPosition);

        %% Apply template axes style before drawing patches

        set(ax, ...
            'FontName', style.FontName, ...
            'FontSize', style.FontSize, ...
            'FontWeight', style.FontWeight, ...
            'LineWidth', style.AxesLineWidth, ...
            'Box', style.Box, ...
            'XGrid', style.XGrid, ...
            'YGrid', style.YGrid, ...
            'GridLineStyle', style.GridLineStyle, ...
            'TickDir', style.TickDir, ...
            'TickLength', style.TickLength, ...
            'Layer', style.Layer, ...
            'YScale', style.YScale, ...
            'XTick', 1:numel(uavLabels), ...
            'XTickLabel', uavLabels, ...
            'XLim', [0.4, numel(uavLabels) + 0.6]);

        % Unified Y-axis across four requirement levels for this metric.
        ylim(ax, metricList(m).globalYLim);
        yticks(ax, metricList(m).globalYTick);
        ax.YTickLabelMode = 'auto';

        %% Draw equal-width touching grouped bars manually

        legendHandles = draw_equal_width_touching_bars( ...
            ax, ...
            Yplot, ...
            stepColors, ...
            singleBarWidth, ...
            style);

        %% Labels and title

        xlabel(ax, '');

        ylabel(ax, metricList(m).yLabelText, ...
            'FontName', style.YLabelFontName, ...
            'FontSize', style.YLabelFontSize, ...
            'FontWeight', style.YLabelFontWeight);

        title(ax, sprintf('%s Requirement', reqLabel), ...
            'FontName', style.TitleFontName, ...
            'FontSize', style.TitleFontSize, ...
            'FontWeight', style.TitleFontWeight);

        %% Legend inside axes

        lgd = legend(ax, legendHandles, stepLabels, ...
            'Location', legendInsideLocation, ...
            'Orientation', legendInsideOrientation, ...
            'Box', legendInsideBox);

        lgd.FontName = style.LegendFontName;
        lgd.FontSize = style.LegendFontSize;
        lgd.FontWeight = style.LegendFontWeight;
        lgd.AutoUpdate = 'off';

        % Keep axes position fixed after legend creation.
        set(ax, 'Position', style.AxesPosition);

        hold(ax, 'off');

        %% Save

        outBase = sprintf('%s_%s', sanitize_filename(reqLabel), metricList(m).fileTag);

        savefig(fig, fullfile(outDir, [outBase, '.fig']));

        exportgraphics(fig, fullfile(outDir, [outBase, '.png']), ...
            'Resolution', 600);

        exportgraphics(fig, fullfile(outDir, [outBase, '.pdf']), ...
            'ContentType', 'vector');

        fprintf('Saved: %s\n', fullfile(outDir, [outBase, '.png']));
    end
end

fprintf('\nAll 12 figures with equal bar width and top Y-axis tick have been generated.\n');
fprintf('Output folder:\n%s\n', outDir);

%% Local functions

function hLegend = draw_equal_width_touching_bars(ax, Y, stepColors, singleBarWidth, style)
    % Draw grouped bars manually using patch objects.
    %
    % Y:
    %   nUAV x nStep
    %
    % stepColors:
    %   nStep x 3
    %
    % Every individual bar has the same width.
    % Bars within the same UAV group touch each other.
    % Requirements with fewer steps naturally occupy a narrower UAV group.

    [nUAV, nStep] = size(Y);

    if nStep < 1
        error('No step data to plot.');
    end

    if size(stepColors, 1) < nStep || size(stepColors, 2) ~= 3
        error('stepColors must be nStep x 3.');
    end

    groupWidth = nStep * singleBarWidth;

    yLim = ylim(ax);

    if strcmpi(get(ax, 'YScale'), 'log')
        yBase = yLim(1);
        if yBase <= 0
            posVals = Y(Y > 0);
            if isempty(posVals)
                yBase = 1;
            else
                yBase = min(posVals, [], 'all') / 10;
            end
        end
    else
        if yLim(1) <= 0 && yLim(2) >= 0
            yBase = 0;
        else
            yBase = yLim(1);
        end
    end

    edgeColor = style.BarEdgeColor;
    if isempty(edgeColor)
        edgeColor = 'none';
    end

    lineWidth = style.BarLineWidth;
    if isempty(lineWidth)
        lineWidth = 0.5;
    end

    faceAlpha = style.BarFaceAlpha;
    if isempty(faceAlpha)
        faceAlpha = 1;
    end

    edgeAlpha = style.BarEdgeAlpha;
    if isempty(edgeAlpha)
        edgeAlpha = 1;
    end

    hLegend = gobjects(1, nStep);

    % Dummy legend handles.
    for k = 1:nStep
        hLegend(k) = patch(ax, ...
            NaN, NaN, stepColors(k, :), ...
            'EdgeColor', edgeColor, ...
            'LineWidth', lineWidth, ...
            'FaceAlpha', faceAlpha, ...
            'EdgeAlpha', edgeAlpha);
    end

    for i = 1:nUAV

        groupLeft = i - groupWidth / 2;

        for k = 1:nStep

            yTop = Y(i, k);

            if isnan(yTop)
                continue;
            end

            if strcmpi(get(ax, 'YScale'), 'log') && yTop <= 0
                continue;
            end

            xLeft  = groupLeft + (k - 1) * singleBarWidth;
            xRight = xLeft + singleBarWidth;

            xPatch = [xLeft, xRight, xRight, xLeft];

            if yTop >= yBase
                yPatch = [yBase, yBase, yTop, yTop];
            else
                yPatch = [yTop, yTop, yBase, yBase];
            end

            patch(ax, ...
                xPatch, ...
                yPatch, ...
                stepColors(k, :), ...
                'EdgeColor', edgeColor, ...
                'LineWidth', lineWidth, ...
                'FaceAlpha', faceAlpha, ...
                'EdgeAlpha', edgeAlpha);
        end
    end
end

function style = read_template_style(templateFile)
    fig = openfig(templateFile, 'invisible');
    cleanupObj = onCleanup(@() close(fig));

    ax = find_main_axes(fig);
    bars = findall(ax, 'Type', 'Bar');

    %% Figure style

    style.FigureColor = get(fig, 'Color');
    style.FigureUnits = get(fig, 'Units');
    style.FigurePosition = get(fig, 'Position');

    style.PaperUnits = get(fig, 'PaperUnits');
    style.PaperPosition = get(fig, 'PaperPosition');

    %% Axes style

    style.AxesUnits = get(ax, 'Units');
    style.AxesPosition = get(ax, 'Position');

    style.FontName = get(ax, 'FontName');
    style.FontSize = get(ax, 'FontSize');
    style.FontWeight = get(ax, 'FontWeight');

    style.AxesLineWidth = get(ax, 'LineWidth');
    style.Box = get(ax, 'Box');
    style.XGrid = get(ax, 'XGrid');
    style.YGrid = get(ax, 'YGrid');
    style.GridLineStyle = get(ax, 'GridLineStyle');
    style.TickDir = get(ax, 'TickDir');
    style.TickLength = get(ax, 'TickLength');
    style.Layer = get(ax, 'Layer');

    style.YScale = get(ax, 'YScale');
    style.TemplateYLim = get(ax, 'YLim');
    style.TemplateYTick = get(ax, 'YTick');

    %% Label and title style

    style.TitleFontName = get(ax.Title, 'FontName');
    style.TitleFontSize = get(ax.Title, 'FontSize');
    style.TitleFontWeight = get(ax.Title, 'FontWeight');

    style.YLabelFontName = get(ax.YLabel, 'FontName');
    style.YLabelFontSize = get(ax.YLabel, 'FontSize');
    style.YLabelFontWeight = get(ax.YLabel, 'FontWeight');

    %% Bar style

    style.BarEdgeColor = [];
    style.BarLineWidth = [];
    style.BarWidth = [];
    style.BarFaceAlpha = [];
    style.BarEdgeAlpha = [];

    if ~isempty(bars)
        b0 = bars(1);

        style.BarEdgeColor = get_prop_if_available(b0, 'EdgeColor', []);
        style.BarLineWidth = get_prop_if_available(b0, 'LineWidth', []);
        style.BarWidth     = get_prop_if_available(b0, 'BarWidth', []);
        style.BarFaceAlpha = get_prop_if_available(b0, 'FaceAlpha', []);
        style.BarEdgeAlpha = get_prop_if_available(b0, 'EdgeAlpha', []);
    end

    %% Legend style

    lgd = findall(fig, 'Type', 'Legend');

    style.LegendFontName = style.FontName;
    style.LegendFontSize = max(style.FontSize - 1, 1);
    style.LegendFontWeight = 'normal';

    if ~isempty(lgd)
        lgd = lgd(1);

        style.LegendFontName = get_prop_if_available(lgd, 'FontName', style.LegendFontName);
        style.LegendFontSize = get_prop_if_available(lgd, 'FontSize', style.LegendFontSize);
        style.LegendFontWeight = get_prop_if_available(lgd, 'FontWeight', style.LegendFontWeight);
    end
end

function ax = find_main_axes(fig)
    axs = findall(fig, 'Type', 'Axes');

    if isempty(axs)
        error('No axes found in template figure.');
    end

    keep = true(size(axs));

    for i = 1:numel(axs)
        tag = lower(string(get(axs(i), 'Tag')));
        if contains(tag, 'legend') || contains(tag, 'colorbar')
            keep(i) = false;
        end
    end

    axs = axs(keep);

    if isempty(axs)
        error('No valid plotting axes found in template figure.');
    end

    nBars = zeros(numel(axs), 1);
    for i = 1:numel(axs)
        nBars(i) = numel(findall(axs(i), 'Type', 'Bar'));
    end

    [~, idx] = max(nBars);
    ax = axs(idx);
end

function valuesOut = values_for_axis(valuesIn, style)
    valuesOut = valuesIn(:);
    valuesOut = valuesOut(~isnan(valuesOut));

    if strcmpi(style.YScale, 'log')
        valuesOut = valuesOut(valuesOut > 0);
    end
end

function [yLimOut, yTickOut] = make_global_y_axis(values, style)
    values = values(:);
    values = values(~isnan(values));

    if isempty(values)
        yLimOut = style.TemplateYLim;
        yTickOut = force_top_y_tick(style.TemplateYTick, yLimOut);
        return;
    end

    if strcmpi(style.YScale, 'log')

        posValues = values(values > 0);

        if isempty(posValues)
            yLimOut = style.TemplateYLim;
            yTickOut = force_top_y_tick(style.TemplateYTick, yLimOut);
            return;
        end

        dataMin = min(posValues);
        dataMax = max(posValues);

        if style.TemplateYLim(1) <= dataMin && style.TemplateYLim(2) >= dataMax
            yLimOut = style.TemplateYLim;
        else
            yMin = 10 ^ floor(log10(dataMin));
            yMax = 10 ^ ceil(log10(dataMax));

            if yMin <= 0 || ~isfinite(yMin)
                yMin = dataMin / 10;
            end

            if yMax <= yMin || ~isfinite(yMax)
                yMax = dataMax * 10;
            end

            yLimOut = [yMin, yMax];
        end

        templateTicks = style.TemplateYTick;
        templateTicks = templateTicks(templateTicks >= yLimOut(1) & templateTicks <= yLimOut(2));

        if numel(templateTicks) >= 2
            yTickOut = templateTicks;
        else
            p1 = floor(log10(yLimOut(1)));
            p2 = ceil(log10(yLimOut(2)));
            yTickOut = 10 .^ (p1:p2);
        end

        yTickOut = force_top_y_tick(yTickOut, yLimOut);

    else

        dataMin = min(values);
        dataMax = max(values);

        if style.TemplateYLim(1) <= dataMin && style.TemplateYLim(2) >= dataMax
            yLimOut = style.TemplateYLim;
            yTickOut = force_top_y_tick(style.TemplateYTick, yLimOut);
            return;
        end

        if dataMin >= 0
            yMin = 0;
        else
            yMin = dataMin - 0.08 * abs(dataMax - dataMin);
        end

        if dataMax == dataMin
            yMax = dataMax + 1;
        else
            yMax = dataMax + 0.12 * abs(dataMax - dataMin);
        end

        if yMax <= yMin
            yMax = yMin + 1;
        end

        yLimOut = [yMin, yMax];

        templateTicks = style.TemplateYTick;

        if numel(templateTicks) >= 2
            dt = median(diff(templateTicks));

            if isfinite(dt) && dt > 0
                firstTick = ceil(yLimOut(1) / dt) * dt;
                lastTick  = floor(yLimOut(2) / dt) * dt;

                yTickOut = firstTick:dt:lastTick;

                if isempty(yTickOut) || numel(yTickOut) < 2
                    yTickOut = linspace(yLimOut(1), yLimOut(2), 5);
                end
            else
                yTickOut = linspace(yLimOut(1), yLimOut(2), 5);
            end
        else
            yTickOut = linspace(yLimOut(1), yLimOut(2), 5);
        end

        yTickOut = force_top_y_tick(yTickOut, yLimOut);
    end
end

function yTickOut = force_top_y_tick(yTickIn, yLimIn)
    % Ensure that the upper end of the Y-axis is labeled.
    % This directly addresses the issue that readers may not know
    % where the Y-axis ends if the top limit is not a tick.

    yTickIn = yTickIn(:).';
    yTickIn = yTickIn(isfinite(yTickIn));

    yTop = yLimIn(2);

    if isempty(yTickIn)
        yTickOut = yTop;
        return;
    end

    tol = max(1e-12, abs(yTop) * 1e-10);

    if all(abs(yTickIn - yTop) > tol)
        yTickOut = sort(unique([yTickIn, yTop]));
    else
        yTickOut = sort(unique(yTickIn));
    end

    % Keep ticks inside YLim.
    yTickOut = yTickOut(yTickOut >= yLimIn(1) & yTickOut <= yLimIn(2));
end

function value = get_prop_if_available(obj, propName, defaultValue)
    value = defaultValue;

    try
        if isprop(obj, propName)
            value = get(obj, propName);
        end
    catch
        value = defaultValue;
    end
end

function name = sanitize_filename(name)
    name = string(name);
    name = strrep(name, ' ', '_');
    name = regexprep(name, '[^\w\-]', '');
    name = char(name);
end