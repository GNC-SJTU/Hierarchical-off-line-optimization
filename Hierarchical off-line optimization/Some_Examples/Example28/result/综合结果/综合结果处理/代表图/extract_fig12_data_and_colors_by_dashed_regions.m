%% extract_fig12_data_and_colors_by_dashed_regions.m
% Extract data and bar colors from the 15 original MATLAB .fig files.
%
% The original figures contain 14 x-axis bar positions, divided by
% three vertical dashed separators into four accuracy-requirement regions:
%   Low, Medium, High, Very High.
%
% This script extracts:
%   1) bar values;
%   2) corresponding bar RGB colors;
%   3) segmented matrices grouped by requirement and UAV.
%
% Output:
%   Fig12_extracted_segmented_data_with_colors.mat
%   Fig12_extracted_segmented_data_with_colors_long_table.csv
%
% Main value arrays:
%   CommCost_all(req, uav, step)
%   CompCost_all(req, uav, step)
%   AccMetric_all(req, uav, step)
%
% Main color arrays:
%   CommColor_all(req, uav, step, rgb)
%   CompColor_all(req, uav, step, rgb)
%   AccColor_all(req, uav, step, rgb)
%
% Requirement order:
%   1 Low
%   2 Medium
%   3 High
%   4 Very High
%
% UAV order:
%   UAV6, UAV13, UAV14, UAV20, UAV25
%
% Missing steps are padded by NaN.

clear; clc; close all;

%% Basic settings

uavIDs = [6, 13, 14, 20, 25];
uavLabels = {'UAV6', 'UAV13', 'UAV14', 'UAV20', 'UAV25'};

reqNames = {'Low', 'Medium', 'High', 'Very_High'};
reqLabels = {'Low', 'Medium', 'High', 'Very High'};

metricList = struct([]);

metricList(1).fieldName  = 'CommunicationCost';
metricList(1).fileSuffix = 'Communication_Cost';
metricList(1).keywords   = {'Communication', 'Cost'};

metricList(2).fieldName  = 'ComputationCost';
metricList(2).fileSuffix = 'Computation_Cost';
metricList(2).keywords   = {'Computation', 'Cost'};

metricList(3).fieldName  = 'AccuracyMetric';
metricList(3).fileSuffix = 'Localization_Error';
metricList(3).keywords   = {'Localization', 'Error'};

nReq = numel(reqNames);
nUAV = numel(uavIDs);

%% Read reference file to determine region lengths

refFile = find_fig_file(uavIDs(1), metricList(1).keywords);

fprintf('Reference file: %s\n', refFile);

refS = read_segmented_bar_data_and_colors_from_fig(refFile);

fprintf('\nDetected x-axis groups in reference file: %d\n', numel(refS.xCenters));
fprintf('Detected dashed separators: ');
disp(refS.separatorX(:).');

fprintf('Detected region lengths:\n');
for r = 1:nReq
    fprintf('  %-10s: %d steps\n', reqLabels{r}, numel(refS.regionIndices{r}));
end

regionStepCounts = cellfun(@numel, refS.regionIndices);
maxSteps = max(regionStepCounts);

%% Initialize arrays
% Value dimensions:
%   requirement x UAV x step
%
% Color dimensions:
%   requirement x UAV x step x RGB

CommCost_all  = nan(nReq, nUAV, maxSteps);
CompCost_all  = nan(nReq, nUAV, maxSteps);
AccMetric_all = nan(nReq, nUAV, maxSteps);

CommColor_all = nan(nReq, nUAV, maxSteps, 3);
CompColor_all = nan(nReq, nUAV, maxSteps, 3);
AccColor_all  = nan(nReq, nUAV, maxSteps, 3);

Raw = struct();
SegmentInfo = struct();

%% Extract all data and colors

for m = 1:numel(metricList)

    metricField = metricList(m).fieldName;
    keywords    = metricList(m).keywords;

    fprintf('\n=== Extracting %s ===\n', metricField);

    for u = 1:nUAV

        uavID = uavIDs(u);
        figFile = find_fig_file(uavID, keywords);

        fprintf('Reading %s ...\n', figFile);

        S = read_segmented_bar_data_and_colors_from_fig(figFile);

        if numel(S.regionValues) ~= nReq
            error('%s: expected %d regions, detected %d.', ...
                figFile, nReq, numel(S.regionValues));
        end

        Raw.(metricField).(sprintf('UAV%d', uavID)) = S;

        if m == 1 && u == 1
            SegmentInfo.xCenters = S.xCenters;
            SegmentInfo.separatorX = S.separatorX;
            SegmentInfo.regionIndices = S.regionIndices;
            SegmentInfo.regionStepCounts = cellfun(@numel, S.regionIndices);
        end

        for r = 1:nReq

            values = S.regionValues{r};
            colors = S.regionColors{r};

            nStep_r = numel(values);

            if size(colors, 1) ~= nStep_r || size(colors, 2) ~= 3
                error('%s: color matrix size does not match extracted values.', figFile);
            end

            switch metricField
                case 'CommunicationCost'
                    CommCost_all(r, u, 1:nStep_r) = values;
                    CommColor_all(r, u, 1:nStep_r, :) = reshape(colors, [1, 1, nStep_r, 3]);

                case 'ComputationCost'
                    CompCost_all(r, u, 1:nStep_r) = values;
                    CompColor_all(r, u, 1:nStep_r, :) = reshape(colors, [1, 1, nStep_r, 3]);

                case 'AccuracyMetric'
                    AccMetric_all(r, u, 1:nStep_r) = values;
                    AccColor_all(r, u, 1:nStep_r, :) = reshape(colors, [1, 1, nStep_r, 3]);
            end
        end
    end
end

%% Build grouped structures
% Each grouped value matrix is:
%   rows    = UAV6, UAV13, UAV14, UAV20, UAV25
%   columns = Step 1, Step 2, ..., Step maxSteps
%
% Each grouped color array is:
%   UAV x step x RGB
%
% Also save reference step colors:
%   StepColors = step x RGB
% using UAV6 as the reference.

Grouped = struct();

for r = 1:nReq

    reqField = reqNames{r};
    nStep_r = regionStepCounts(r);

    Grouped.(reqField).RequirementLabel = reqLabels{r};
    Grouped.(reqField).UAVLabels = uavLabels;
    Grouped.(reqField).StepLabels = arrayfun(@(k) sprintf('Step %d', k), ...
        1:maxSteps, 'UniformOutput', false);
    Grouped.(reqField).AvailableStepCount = nStep_r;

    Grouped.(reqField).CommunicationCost = squeeze(CommCost_all(r, :, :));
    Grouped.(reqField).ComputationCost   = squeeze(CompCost_all(r, :, :));
    Grouped.(reqField).AccuracyMetric    = squeeze(AccMetric_all(r, :, :));

    Grouped.(reqField).CommunicationCostColors = squeeze(CommColor_all(r, :, :, :));
    Grouped.(reqField).ComputationCostColors   = squeeze(CompColor_all(r, :, :, :));
    Grouped.(reqField).AccuracyMetricColors    = squeeze(AccColor_all(r, :, :, :));

    Grouped.(reqField).CommunicationCostStepColors = ...
        reshape(CommColor_all(r, 1, 1:nStep_r, :), [nStep_r, 3]);

    Grouped.(reqField).ComputationCostStepColors = ...
        reshape(CompColor_all(r, 1, 1:nStep_r, :), [nStep_r, 3]);

    Grouped.(reqField).AccuracyMetricStepColors = ...
        reshape(AccColor_all(r, 1, 1:nStep_r, :), [nStep_r, 3]);
end

%% Build long-format table for manual checking

LongTable = make_long_table_with_colors( ...
    CommCost_all, CompCost_all, AccMetric_all, ...
    CommColor_all, CompColor_all, AccColor_all, ...
    reqLabels, uavLabels, maxSteps);

%% Sanity checks

if all(isnan(AccMetric_all(:)))
    warning('AccMetric_all is all NaN. Please check Localization_Error .fig file names or extraction logic.');
else
    fprintf('\nAccuracyMetric extraction check passed: AccMetric_all contains valid values.\n');
end

if all(isnan(AccColor_all(:)))
    warning('AccColor_all is all NaN. Please check bar color extraction for Localization_Error figures.');
else
    fprintf('AccuracyMetric color extraction check passed: AccColor_all contains valid RGB values.\n');
end

save('Fig12_extracted_segmented_data_with_colors.mat', ...
    'CommCost_all', ...
    'CompCost_all', ...
    'AccMetric_all', ...
    'CommColor_all', ...
    'CompColor_all', ...
    'AccColor_all', ...
    'Grouped', ...
    'Raw', ...
    'LongTable', ...
    'SegmentInfo', ...
    'uavIDs', ...
    'uavLabels', ...
    'reqNames', ...
    'reqLabels', ...
    'regionStepCounts', ...
    'maxSteps');

writetable(LongTable, 'Fig12_extracted_segmented_data_with_colors_long_table.csv');

fprintf('\nExtraction completed.\n');
fprintf('Saved MAT file: Fig12_extracted_segmented_data_with_colors.mat\n');
fprintf('Saved CSV file: Fig12_extracted_segmented_data_with_colors_long_table.csv\n');

%% Quick display

for r = 1:nReq

    reqField = reqNames{r};

    fprintf('\n--- %s requirement ---\n', reqLabels{r});
    fprintf('Available steps: %d\n', Grouped.(reqField).AvailableStepCount);

    validSteps = 1:Grouped.(reqField).AvailableStepCount;
    validStepLabels = Grouped.(reqField).StepLabels(validSteps);
    validVarNames = matlab.lang.makeValidName(validStepLabels);

    disp('CommunicationCost:');
    disp(array2table(Grouped.(reqField).CommunicationCost(:, validSteps), ...
        'RowNames', uavLabels, ...
        'VariableNames', validVarNames));

    disp('CommunicationCostStepColors from UAV6:');
    disp(Grouped.(reqField).CommunicationCostStepColors);

    disp('ComputationCost:');
    disp(array2table(Grouped.(reqField).ComputationCost(:, validSteps), ...
        'RowNames', uavLabels, ...
        'VariableNames', validVarNames));

    disp('ComputationCostStepColors from UAV6:');
    disp(Grouped.(reqField).ComputationCostStepColors);

    disp('AccuracyMetric:');
    disp(array2table(Grouped.(reqField).AccuracyMetric(:, validSteps), ...
        'RowNames', uavLabels, ...
        'VariableNames', validVarNames));

    disp('AccuracyMetricStepColors from UAV6:');
    disp(Grouped.(reqField).AccuracyMetricStepColors);
end

%% Local functions

function figFile = find_fig_file(uavID, keywords)
    allFiles = dir('*.fig');

    if isempty(allFiles)
        error('No .fig files found in the current folder.');
    end

    candidates = {};

    for k = 1:numel(allFiles)

        name = allFiles(k).name;
        nameLower = lower(name);

        pattern1 = sprintf('(^|[^0-9])%d([^0-9]|$)', uavID);
        pattern2 = sprintf('uav\\s*%d', uavID);

        hasUAV = ~isempty(regexp(nameLower, pattern1, 'once')) || ...
                 ~isempty(regexp(nameLower, pattern2, 'once'));

        if ~hasUAV
            continue;
        end

        hasAllKeywords = true;
        for j = 1:numel(keywords)
            if ~contains(nameLower, lower(keywords{j}))
                hasAllKeywords = false;
                break;
            end
        end

        if hasAllKeywords
            candidates{end+1} = name; %#ok<AGROW>
        end
    end

    if isempty(candidates)
        error('Cannot find .fig file for UAV%d with keywords: %s', ...
            uavID, strjoin(keywords, ', '));
    end

    if numel(candidates) > 1
        fprintf('Multiple candidates found for UAV%d with keywords %s:\n', ...
            uavID, strjoin(keywords, ', '));
        disp(candidates(:));
        fprintf('Using the first one: %s\n', candidates{1});
    end

    figFile = candidates{1};
end

function S = read_segmented_bar_data_and_colors_from_fig(figFile)
    fig = openfig(figFile, 'invisible');
    cleanupObj = onCleanup(@() close(fig));

    ax = find_main_axes(fig);

    [xCenters, yValues, barColors] = extract_single_sequence_from_bars(ax, figFile);

    separatorX = detect_vertical_dashed_separators(ax);

    if numel(separatorX) < 3
        warning(['%s: fewer than three vertical dashed separators detected. ', ...
                 'Using fallback segmentation [2, 3, 4, 5].'], figFile);

        if numel(yValues) ~= 14
            error(['Fallback segmentation requires 14 x-axis groups, ', ...
                   'but %s has %d groups.'], figFile, numel(yValues));
        end

        regionIndices = {
            1:2
            3:5
            6:9
            10:14
        };
    else
        separatorX = sort(separatorX(:).');

        xMin = min(xCenters);
        xMax = max(xCenters);

        separatorX = separatorX(separatorX > xMin & separatorX < xMax);

        if numel(separatorX) < 3
            warning(['%s: dashed lines were found but fewer than three are inside x range. ', ...
                     'Using fallback segmentation [2, 3, 4, 5].'], figFile);

            if numel(yValues) ~= 14
                error(['Fallback segmentation requires 14 x-axis groups, ', ...
                       'but %s has %d groups.'], figFile, numel(yValues));
            end

            regionIndices = {
                1:2
                3:5
                6:9
                10:14
            };
        else
            if numel(separatorX) > 3
                separatorX = choose_three_internal_separators(separatorX, xCenters);
            end

            b1 = separatorX(1);
            b2 = separatorX(2);
            b3 = separatorX(3);

            regionIndices = {
                find(xCenters < b1)
                find(xCenters > b1 & xCenters < b2)
                find(xCenters > b2 & xCenters < b3)
                find(xCenters > b3)
            };
        end
    end

    regionValues = cell(4, 1);
    regionColors = cell(4, 1);

    for r = 1:4
        idx = regionIndices{r};
        regionValues{r} = yValues(idx);
        regionColors{r} = barColors(idx, :);
    end

    S.figFile = figFile;
    S.xCenters = xCenters(:).';
    S.yValues = yValues(:).';
    S.barColors = barColors;
    S.separatorX = separatorX(:).';
    S.regionIndices = regionIndices;
    S.regionValues = regionValues;
    S.regionColors = regionColors;
    S.axesTitle = get_axes_title(ax);
end

function ax = find_main_axes(fig)
    axs = findall(fig, 'Type', 'Axes');

    if isempty(axs)
        error('No axes found in figure.');
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
        error('No valid plotting axes found in figure.');
    end

    nBars = zeros(numel(axs), 1);
    for i = 1:numel(axs)
        nBars(i) = numel(findall(axs(i), 'Type', 'Bar'));
    end

    [~, idx] = max(nBars);
    ax = axs(idx);
end

function [xCenters, yValues, barColors] = extract_single_sequence_from_bars(ax, figFile)
    bars = findall(ax, 'Type', 'Bar');

    if isempty(bars)
        error('No bar objects found in %s.', figFile);
    end

    if numel(bars) == 1
        b = bars(1);

        xCenters = get_bar_xdata(b);
        yValues  = b.YData(:).';

        if isempty(xCenters)
            xCenters = 1:numel(yValues);
        end

        barColors = get_colors_for_bar_object(b, numel(yValues));

        [xCenters, order] = sort(xCenters(:).');
        yValues = yValues(order);
        barColors = barColors(order, :);

        return;
    end

    xs = [];
    ys = [];
    cs = [];

    for k = 1:numel(bars)
        b = bars(k);

        xk = get_bar_xdata(b);
        yk = b.YData(:).';

        if isempty(xk)
            xk = 1:numel(yk);
        end

        if numel(xk) ~= numel(yk)
            try
                xk = b.XEndPoints;
            catch
                error('Cannot determine bar x positions in %s.', figFile);
            end
        end

        ck = get_colors_for_bar_object(b, numel(yk));

        xs = [xs, xk(:).']; %#ok<AGROW>
        ys = [ys, yk(:).']; %#ok<AGROW>
        cs = [cs; ck]; %#ok<AGROW>
    end

    [xs, order] = sort(xs);
    ys = ys(order);
    cs = cs(order, :);

    tol = 1e-6;
    xUnique = [];
    yUnique = [];
    cUnique = [];

    i = 1;
    while i <= numel(xs)
        j = i;
        while j < numel(xs) && abs(xs(j+1) - xs(i)) < tol
            j = j + 1;
        end

        xUnique(end+1) = mean(xs(i:j)); %#ok<AGROW>

        if j == i
            yUnique(end+1) = ys(i); %#ok<AGROW>
            cUnique(end+1, :) = cs(i, :); %#ok<AGROW>
        else
            yUnique(end+1) = sum(ys(i:j), 'omitnan'); %#ok<AGROW>
            cUnique(end+1, :) = mean(cs(i:j, :), 1, 'omitnan'); %#ok<AGROW>
        end

        i = j + 1;
    end

    xCenters = xUnique;
    yValues = yUnique;
    barColors = cUnique;
end

function xData = get_bar_xdata(b)
    xData = [];

    try
        xData = b.XData;
    catch
        xData = [];
    end

    if isempty(xData)
        try
            xData = b.XEndPoints;
        catch
            xData = [];
        end
    end

    xData = xData(:).';
end

function colors = get_colors_for_bar_object(b, nBars)
    colors = nan(nBars, 3);

    try
        fc = b.FaceColor;
    catch
        fc = [];
    end

    if isnumeric(fc) && numel(fc) == 3
        colors = repmat(double(fc(:).'), nBars, 1);
        return;
    end

    try
        cd = b.CData;
    catch
        cd = [];
    end

    if isnumeric(cd) && ~isempty(cd)

        if size(cd, 1) == nBars && size(cd, 2) == 3
            colors = double(cd(:, 1:3));
            return;
        end

        if size(cd, 1) >= nBars && size(cd, 2) >= 3
            colors = double(cd(1:nBars, 1:3));
            return;
        end

        if size(cd, 1) == 1 && size(cd, 2) == 3
            colors = repmat(double(cd), nBars, 1);
            return;
        end

        if isvector(cd) && numel(cd) == nBars
            ax = ancestor(b, 'axes');
            try
                cmap = colormap(ax);
                clim = get(ax, 'CLim');
                colors = map_cdata_to_rgb(double(cd(:)), cmap, clim);
                return;
            catch
            end
        end
    end

    try
        ax = ancestor(b, 'axes');
        colorOrder = get(ax, 'ColorOrder');

        idx = 1;
        if isprop(b, 'SeriesIndex')
            idx = b.SeriesIndex;
        end

        idx = mod(idx - 1, size(colorOrder, 1)) + 1;
        colors = repmat(colorOrder(idx, :), nBars, 1);
        return;
    catch
    end

    colors = repmat([0, 0.4470, 0.7410], nBars, 1);
end

function rgb = map_cdata_to_rgb(cdata, cmap, clim)
    cdata = cdata(:);

    if clim(2) == clim(1)
        idx = ones(size(cdata));
    else
        idx = round(1 + (cdata - clim(1)) ./ (clim(2) - clim(1)) .* (size(cmap, 1) - 1));
    end

    idx = max(1, min(size(cmap, 1), idx));
    rgb = cmap(idx, :);
end

function separatorX = detect_vertical_dashed_separators(ax)
    separatorX = [];

    lines = findall(ax, 'Type', 'Line');

    for k = 1:numel(lines)
        ln = lines(k);

        try
            lineStyle = string(ln.LineStyle);
            x = ln.XData;
            y = ln.YData;
        catch
            continue;
        end

        if isempty(x) || isempty(y)
            continue;
        end

        x = x(:).';
        y = y(:).';

        isDashed = lineStyle == "--" || lineStyle == "-.";

        if ~isDashed
            continue;
        end

        if max(x) - min(x) < 1e-8 && max(y) - min(y) > 1e-8
            separatorX(end+1) = mean(x); %#ok<AGROW>
        end
    end

    % Also support xline objects, whose type may be ConstantLine.
    allObjs = findall(ax);

    for k = 1:numel(allObjs)
        obj = allObjs(k);

        if isprop(obj, 'Value') && isprop(obj, 'Orientation') && isprop(obj, 'LineStyle')
            try
                orientation = string(obj.Orientation);
                lineStyle = string(obj.LineStyle);

                isDashed = lineStyle == "--" || lineStyle == "-.";

                if strcmpi(orientation, "vertical") && isDashed
                    separatorX(end+1) = double(obj.Value); %#ok<AGROW>
                end
            catch
            end
        end
    end

    if ~isempty(separatorX)
        separatorX = unique(round(separatorX * 1e8) / 1e8);
    end
end

function selected = choose_three_internal_separators(separatorX, xCenters)
    separatorX = sort(separatorX(:).');
    nX = numel(xCenters);

    if nX == 14
        expected = [
            mean(xCenters([2, 3])), ...
            mean(xCenters([5, 6])), ...
            mean(xCenters([9, 10]))
        ];

        selected = zeros(1, 3);
        remaining = separatorX;

        for i = 1:3
            [~, idx] = min(abs(remaining - expected(i)));
            selected(i) = remaining(idx);
            remaining(idx) = [];
        end

        selected = sort(selected);
        return;
    end

    target = linspace(min(xCenters), max(xCenters), 5);
    expected = target(2:4);

    selected = zeros(1, 3);
    remaining = separatorX;

    for i = 1:3
        [~, idx] = min(abs(remaining - expected(i)));
        selected(i) = remaining(idx);
        remaining(idx) = [];
    end

    selected = sort(selected);
end

function titleText = get_axes_title(ax)
    titleText = '';

    try
        titleText = ax.Title.String;
        if iscell(titleText)
            titleText = strjoin(titleText, ' ');
        end
    catch
        titleText = '';
    end
end

function T = make_long_table_with_colors( ...
    CommCost_all, CompCost_all, AccMetric_all, ...
    CommColor_all, CompColor_all, AccColor_all, ...
    reqLabels, uavLabels, maxSteps)

    Requirement = {};
    UAV = {};
    Step = [];

    CommunicationCost = [];
    ComputationCost = [];
    AccuracyMetric = [];

    CommColor_R = [];
    CommColor_G = [];
    CommColor_B = [];

    CompColor_R = [];
    CompColor_G = [];
    CompColor_B = [];

    AccColor_R = [];
    AccColor_G = [];
    AccColor_B = [];

    nReq = numel(reqLabels);
    nUAV = numel(uavLabels);

    for r = 1:nReq
        for u = 1:nUAV
            for s = 1:maxSteps

                c1 = CommCost_all(r, u, s);
                c2 = CompCost_all(r, u, s);
                c3 = AccMetric_all(r, u, s);

                if isnan(c1) && isnan(c2) && isnan(c3)
                    continue;
                end

                commRGB = reshape(CommColor_all(r, u, s, :), [1, 3]);
                compRGB = reshape(CompColor_all(r, u, s, :), [1, 3]);
                accRGB  = reshape(AccColor_all(r, u, s, :), [1, 3]);

                Requirement{end+1, 1} = reqLabels{r}; %#ok<AGROW>
                UAV{end+1, 1} = uavLabels{u}; %#ok<AGROW>
                Step(end+1, 1) = s; %#ok<AGROW>

                CommunicationCost(end+1, 1) = c1; %#ok<AGROW>
                ComputationCost(end+1, 1) = c2; %#ok<AGROW>
                AccuracyMetric(end+1, 1) = c3; %#ok<AGROW>

                CommColor_R(end+1, 1) = commRGB(1); %#ok<AGROW>
                CommColor_G(end+1, 1) = commRGB(2); %#ok<AGROW>
                CommColor_B(end+1, 1) = commRGB(3); %#ok<AGROW>

                CompColor_R(end+1, 1) = compRGB(1); %#ok<AGROW>
                CompColor_G(end+1, 1) = compRGB(2); %#ok<AGROW>
                CompColor_B(end+1, 1) = compRGB(3); %#ok<AGROW>

                AccColor_R(end+1, 1) = accRGB(1); %#ok<AGROW>
                AccColor_G(end+1, 1) = accRGB(2); %#ok<AGROW>
                AccColor_B(end+1, 1) = accRGB(3); %#ok<AGROW>
            end
        end
    end

    T = table(Requirement, UAV, Step, ...
        CommunicationCost, ComputationCost, AccuracyMetric, ...
        CommColor_R, CommColor_G, CommColor_B, ...
        CompColor_R, CompColor_G, CompColor_B, ...
        AccColor_R, AccColor_G, AccColor_B);
end