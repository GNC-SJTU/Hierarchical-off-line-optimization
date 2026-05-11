%% draw_12_bar_figures_equal_bar_width_final_layout.m
% Draw 12 separated bar figures from extracted Fig. 12 data.
%
% Features:
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
%
%   7) The upper end of each Y-axis is always labeled with a tick value.
%
%   8) Only CommunicationCost figures have Y-axis labels.
%      The label is the corresponding requirement name.
%
%   9) CommunicationCost figure window is widened on the left side,
%      while the axes size and the top/right margins are kept unchanged.
%
%  10) X-axis tick labels are 6, 13, 14, 20, 25, with "UAV" shown
%      at the right end of the x-axis.

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

outDir = fullfile(pwd, 'Fig12_12_separate_bar_figures_final_layout');

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
legendInsideOrientation = 'horizontal';
legendInsideBox         = 'on';

%% Bar width setting
% Every individual bar has exactly the same width in all 12 figures.

singleBarWidth = 0.18;

%% Communication figure widening setting
% Increase the figure width on the left side only.
% Axes width/height are unchanged.
% Axes-to-right-margin and axes-to-top-margin are unchanged.

commExtraLeftInch = 0.25;

%% X-axis tick labels

uavTickLabels = regexprep(uavLabels, '^UAV', '');

%% Requirement labels shown only on CommunicationCost Y-axis

requirementYLabels = { ...
    'Low requirement', ...
    'Medium requirement', ...
    'High requirement', ...
    'Very high requirement'};

%% Metric settings

metricList(1).fieldName  = 'CommunicationCost';
metricList(1).colorField = 'CommunicationCostStepColors';
metricList(1).fileTag    = 'CommunicationCost';
metricList(1).template   = templateComm;
metricList(1).titleText  = 'Communication Cost';

metricList(2).fieldName  = 'ComputationCost';
metricList(2).colorField = 'ComputationCostStepColors';
metricList(2).fileTag    = 'ComputationCost';
metricList(2).template   = templateComp;
metricList(2).titleText  = 'Computation Cost';

metricList(3).fieldName  = 'AccuracyMetric';
metricList(3).colorField = 'AccuracyMetricStepColors';
metricList(3).fileTag    = 'AccuracyMetric';
metricList(3).template   = templateAcc;
metricList(3).titleText  = 'Accuracy Metric tr(\bfP)';

%% Read template styles

for m = 1:numel(metricList)
    metricList(m).style = read_template_style(metricList(m).template);
end

% Widen only the CommunicationCost figure window on the left side.
metricList(1).style = widen_figure_left_keep_axes(metricList(1).style, commExtraLeftInch);

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

    if strcmp(metricList(m).fieldName, 'AccuracyMetric')
        % Use the reference accuracy figure's Y-axis exactly.
        % This keeps Accuracy Y-grid identical to the uploaded reference figure.
        globalYLim  = style.TemplateYLim;
        globalYTick = style.TemplateYTick;
    else
        [globalYLim, globalYTick] = make_global_y_axis(values_for_axis(allValues, style), style);
        globalYTick = force_top_y_tick(globalYTick, globalYLim);
    end
    
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

        %% Apply template axes style

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
            'XTickLabel', uavTickLabels, ...
            'XLim', [0.4, numel(uavLabels) + 0.6]);

        % Unified Y-axis across four requirement levels for this metric.
        ylim(ax, metricList(m).globalYLim);
        yticks(ax, metricList(m).globalYTick);
        ax.YTickLabelMode = 'auto';

        % Force AccuracyMetric figures to have light-gray dashed Y-grid,
        % consistent with the other two types of plots.

        % For AccuracyMetric figures, copy the Y-axis and Y-grid style
        % directly from the uploaded accuracy reference figure.
        if strcmp(metricField, 'AccuracyMetric')
            apply_accuracy_ygrid_from_template(ax, style);
        end


        %% Draw equal-width touching grouped bars manually

        legendHandles = draw_equal_width_touching_bars( ...
            ax, ...
            Yplot, ...
            stepColors, ...
            singleBarWidth, ...
            style);

        %% Y-axis label
        % Only CommunicationCost figures have Y-axis labels.
        % ComputationCost and AccuracyMetric figures have no Y-axis label.

        if m == 1
            ylabel(ax, requirementYLabels{r}, ...
                'FontName', 'Times New Roman', ...
                'FontSize', 9.9, ...
                'FontWeight', 'normal');
        else
            ylabel(ax, '');
        end

%% X-axis left-side label: UAV

% Put "UAV" before the UAV index numbers on the x-axis.
% This avoids clipping on the right side and avoids covering the tick labels.
xlabel(ax, '');

text(ax, 0.045, -0.035, 'UAV', ...
    'Units', 'normalized', ...
    'FontName', style.XLabelFontName, ...
    'FontSize', style.XLabelFontSize, ...
    'FontWeight', style.XLabelFontWeight, ...
    'HorizontalAlignment', 'right', ...
    'VerticalAlignment', 'top', ...
    'Clipping', 'off');

        %% Title
        
        title(ax, metricList(m).titleText, ...
            'FontName', 'Times New Roman', ...
            'FontSize', 9.9, ...
            'FontWeight', 'normal', ...
            'Interpreter', 'tex');
        %% Legend inside axes

        lgd = legend(ax, legendHandles, stepLabels, ...
            'Location', legendInsideLocation, ...
            'Orientation', legendInsideOrientation, ...
            'Box', legendInsideBox);
        
        lgd.FontName = style.LegendFontName;
        lgd.FontSize = style.LegendFontSize;
        lgd.FontWeight = style.LegendFontWeight;
        lgd.AutoUpdate = 'off';
        
        % Force all legend entries to stay in one horizontal row.
        if isprop(lgd, 'NumColumns')
            lgd.NumColumns = nStep;
        end

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

fprintf('\nAll 12 final-layout figures have been generated.\n');
fprintf('Output folder:\n%s\n', outDir);

%% Local functions

function hLegend = draw_equal_width_touching_bars(ax, Y, stepColors, singleBarWidth, style)
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

    % Use inch units to make left-side widening deterministic.
    set(fig, 'Units', 'inches');

    ax = find_main_axes(fig);
    set(ax, 'Units', 'inches');

    bars = findall(ax, 'Type', 'Bar');

    %% Figure style

    style.FigureColor = get(fig, 'Color');
    style.FigureUnits = 'inches';
    style.FigurePosition = get(fig, 'Position');

    style.PaperUnits = 'inches';
    set(fig, 'PaperUnits', 'inches');
    style.PaperPosition = get(fig, 'PaperPosition');

    %% Axes style

    style.AxesUnits = 'inches';
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
    
    % Major grid style
    style.GridColor = get_prop_if_available(ax, 'GridColor', []);
    style.GridAlpha = get_prop_if_available(ax, 'GridAlpha', []);
    style.GridLineStyle = get_prop_if_available(ax, 'GridLineStyle', []);
    
    % Minor grid style
    style.YMinorGrid = get_prop_if_available(ax, 'YMinorGrid', 'off');
    style.YMinorTick = get_prop_if_available(ax, 'YMinorTick', 'off');
    style.MinorGridLineStyle = get_prop_if_available(ax, 'MinorGridLineStyle', []);
    style.MinorGridColor = get_prop_if_available(ax, 'MinorGridColor', []);
    style.MinorGridAlpha = get_prop_if_available(ax, 'MinorGridAlpha', []);
    
    % Minor tick positions, if available
    style.YMinorTickValues = [];
    
    try
        style.YMinorTickValues = ax.YAxis.MinorTickValues;
    catch
        style.YMinorTickValues = [];
    end

    %% Label and title style

    style.TitleFontName = get(ax.Title, 'FontName');
    style.TitleFontSize = get(ax.Title, 'FontSize');
    style.TitleFontWeight = get(ax.Title, 'FontWeight');

    style.YLabelFontName = get(ax.YLabel, 'FontName');
    style.YLabelFontSize = get(ax.YLabel, 'FontSize');
    style.YLabelFontWeight = get(ax.YLabel, 'FontWeight');

    style.XLabelFontName = get(ax.XLabel, 'FontName');
    style.XLabelFontSize = get(ax.XLabel, 'FontSize');
    style.XLabelFontWeight = get(ax.XLabel, 'FontWeight');

    if isempty(style.XLabelFontName)
        style.XLabelFontName = style.FontName;
    end

    if isempty(style.XLabelFontSize) || style.XLabelFontSize <= 0
        style.XLabelFontSize = style.FontSize;
    end

    if isempty(style.XLabelFontWeight)
        style.XLabelFontWeight = style.FontWeight;
    end

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

function style = widen_figure_left_keep_axes(style, extraLeftInch)
    if extraLeftInch <= 0
        return;
    end

    style.FigureUnits = 'inches';
    style.AxesUnits = 'inches';
    style.PaperUnits = 'inches';

    % Move the figure's screen position left and increase width.
    % This keeps the figure's right edge roughly unchanged on screen.
    style.FigurePosition(1) = style.FigurePosition(1) - extraLeftInch;
    style.FigurePosition(3) = style.FigurePosition(3) + extraLeftInch;

    % Shift the axes right by the same amount.
    % Axes width/height are unchanged.
    % Right and top margins are unchanged.
    style.AxesPosition(1) = style.AxesPosition(1) + extraLeftInch;

    % Increase paper width for export.
    style.PaperPosition(3) = style.PaperPosition(3) + extraLeftInch;
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

function apply_accuracy_ygrid_from_template(ax, style)
    % Copy Y-axis and Y-grid settings from the accuracy template figure.
    % This is used to make all AccuracyMetric figures match the uploaded
    % reference figure's Y-grid style.

    ylim(ax, style.TemplateYLim);
    yticks(ax, style.TemplateYTick);

    set(ax, ...
        'YGrid', style.YGrid, ...
        'XGrid', style.XGrid, ...
        'YMinorGrid', style.YMinorGrid, ...
        'YMinorTick', style.YMinorTick);

    set_prop_if_available(ax, 'GridLineStyle', style.GridLineStyle);
    set_prop_if_available(ax, 'GridColor', style.GridColor);
    set_prop_if_available(ax, 'GridAlpha', style.GridAlpha);

    set_prop_if_available(ax, 'MinorGridLineStyle', style.MinorGridLineStyle);
    set_prop_if_available(ax, 'MinorGridColor', style.MinorGridColor);
    set_prop_if_available(ax, 'MinorGridAlpha', style.MinorGridAlpha);

    if ~isempty(style.YMinorTickValues)
        try
            ax.YAxis.MinorTickValues = style.YMinorTickValues;
        catch
        end
    end

    ax.YTickLabelMode = 'auto';
end

function set_prop_if_available(obj, propName, propValue)
    if isempty(propValue)
        return;
    end

    try
        if isprop(obj, propName)
            set(obj, propName, propValue);
        end
    catch
    end
end