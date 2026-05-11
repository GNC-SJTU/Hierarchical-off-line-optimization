%% extract_fig12_data_by_dashed_regions.m
% Extract data from the 15 original MATLAB .fig files.
%
% The original .fig files do NOT have only four x-axis groups.
% Instead, the x-axis contains step-level bars, and three vertical dashed
% lines divide the x-axis into four regions:
%   Low, Medium, High, Very High.
%
% This script:
%   1) reads the 15 .fig files in the current folder;
%   2) detects the three vertical dashed separator lines;
%   3) splits the 14 x-axis bars into four requirement regions;
%   4) stores the data as matrices grouped by requirement and UAV.
%
% Output:
%   Fig12_extracted_segmented_data.mat
%   Fig12_extracted_segmented_data_long_table.csv
%
% Main arrays:
%   CommCost_all(req, uav, step)
%   CompCost_all(req, uav, step)
%   AccMetric_all(req, uav, step)
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
% For example, if Low has only 2 steps and maxSteps = 5,
% then CommCost_all(1,u,3:5) = NaN.

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

refS = read_segmented_bar_data_from_fig(refFile);

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
% Dimensions:
%   requirement x UAV x step

CommCost_all  = nan(nReq, nUAV, maxSteps);
CompCost_all  = nan(nReq, nUAV, maxSteps);
AccMetric_all = nan(nReq, nUAV, maxSteps);

Raw = struct();
SegmentInfo = struct();

%% Extract all data

for m = 1:numel(metricList)

    metricField = metricList(m).fieldName;
    keywords    = metricList(m).keywords;

    fprintf('\n=== Extracting %s ===\n', metricField);

    for u = 1:nUAV

        uavID = uavIDs(u);
        figFile = find_fig_file(uavID, keywords);

        fprintf('Reading %s ...\n', figFile);

        S = read_segmented_bar_data_from_fig(figFile);

        % Basic consistency check
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
            nStep_r = numel(values);

            switch metricField
                case 'CommunicationCost'
                    CommCost_all(r, u, 1:nStep_r) = values;

                case 'ComputationCost'
                    CompCost_all(r, u, 1:nStep_r) = values;

                case 'AccuracyMetric'
                    AccMetric_all(r, u, 1:nStep_r) = values;
            end
        end
    end
end

%% Build grouped structures
% Each grouped matrix is:
%   rows    = UAV6, UAV13, UAV14, UAV20, UAV25
%   columns = Step 1, Step 2, ..., Step maxSteps
%
% Unavailable steps are NaN.

Grouped = struct();

for r = 1:nReq

    reqField = reqNames{r};

    Grouped.(reqField).RequirementLabel = reqLabels{r};
    Grouped.(reqField).UAVLabels = uavLabels;
    Grouped.(reqField).StepLabels = arrayfun(@(k) sprintf('Step %d', k), ...
        1:maxSteps, 'UniformOutput', false);
    Grouped.(reqField).AvailableStepCount = regionStepCounts(r);

    Grouped.(reqField).CommunicationCost = squeeze(CommCost_all(r, :, :));
    Grouped.(reqField).ComputationCost   = squeeze(CompCost_all(r, :, :));
    Grouped.(reqField).AccuracyMetric    = squeeze(AccMetric_all(r, :, :));
end

%% Build long-format table for manual checking

LongTable = make_long_table( ...
    CommCost_all, CompCost_all, AccMetric_all, ...
    reqLabels, uavLabels, maxSteps);

%% Save outputs

save('Fig12_extracted_segmented_data.mat', ...
    'CommCost_all', ...
    'CompCost_all', ...
    'AccMetric_all', ...
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

writetable(LongTable, 'Fig12_extracted_segmented_data_long_table.csv');

fprintf('\nExtraction completed.\n');
fprintf('Saved MAT file: Fig12_extracted_segmented_data.mat\n');
fprintf('Saved CSV file: Fig12_extracted_segmented_data_long_table.csv\n');

%% Quick display

for r = 1:nReq
    reqField = reqNames{r};

    fprintf('\n--- %s requirement ---\n', reqLabels{r});
    fprintf('Available steps: %d\n', Grouped.(reqField).AvailableStepCount);

    disp('CommunicationCost:');
    disp(array2table(Grouped.(reqField).CommunicationCost, ...
        'RowNames', uavLabels, ...
        'VariableNames', matlab.lang.makeValidName(Grouped.(reqField).StepLabels)));

    disp('ComputationCost:');
    disp(array2table(Grouped.(reqField).ComputationCost, ...
        'RowNames', uavLabels, ...
        'VariableNames', matlab.lang.makeValidName(Grouped.(reqField).StepLabels)));

    disp('AccuracyMetric:');
    disp(array2table(Grouped.(reqField).AccuracyMetric, ...
        'RowNames', uavLabels, ...
        'VariableNames', matlab.lang.makeValidName(Grouped.(reqField).StepLabels)));
end

%% Local functions

function figFile = find_fig_file(uavID, keywords)
    % Find a .fig file for a given UAV and metric keywords.
    %
    % Example:
    %   uavID = 6
    %   keywords = {'Communication', 'Cost'}
    %
    % This function accepts file names such as:
    %   6_Communication_Cost.fig
    %   UAV6_Communication_Cost.fig
    %   6 Communication Cost.fig

    allFiles = dir('*.fig');

    if isempty(allFiles)
        error('No .fig files found in the current folder.');
    end

    candidates = {};

    for k = 1:numel(allFiles)

        name = allFiles(k).name;
        nameLower = lower(name);

        % UAV id should appear as an isolated number or after UAV.
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

function S = read_segmented_bar_data_from_fig(figFile)
    % Read a .fig file whose x-axis contains step-level bars and whose
    % four requirement regions are divided by three vertical dashed lines.
    %
    % Output:
    %   S.xCenters:
    %       x positions of the bars, usually 1:14
    %
    %   S.yValues:
    %       bar values in x-axis order
    %
    %   S.separatorX:
    %       x positions of vertical dashed separator lines
    %
    %   S.regionIndices:
    %       cell array of indices for Low, Medium, High, Very High
    %
    %   S.regionValues:
    %       cell array of values for Low, Medium, High, Very High

    fig = openfig(figFile, 'invisible');
    cleanupObj = onCleanup(@() close(fig));

    ax = find_main_axes(fig);

    [xCenters, yValues] = extract_single_sequence_from_bars(ax, figFile);

    separatorX = detect_vertical_dashed_separators(ax);

    % If dashed separators cannot be detected, use the known 14-bar pattern.
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

        % Use only three internal separators if more dashed vertical lines exist.
        % Select the three separators lying inside the x range.
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
            % If more than three separator candidates exist, choose three
            % most representative ones. For the original Fig. 12 files,
            % these should be near 2.5, 5.5, and 9.5.
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
    for r = 1:4
        idx = regionIndices{r};
        regionValues{r} = yValues(idx);
    end

    S.figFile = figFile;
    S.xCenters = xCenters(:).';
    S.yValues = yValues(:).';
    S.separatorX = separatorX(:).';
    S.regionIndices = regionIndices;
    S.regionValues = regionValues;
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

    % Choose the axes with the largest number of bar objects.
    nBars = zeros(numel(axs), 1);
    for i = 1:numel(axs)
        nBars(i) = numel(findall(axs(i), 'Type', 'Bar'));
    end

    [~, idx] = max(nBars);
    ax = axs(idx);
end

function [xCenters, yValues] = extract_single_sequence_from_bars(ax, figFile)
    bars = findall(ax, 'Type', 'Bar');

    if isempty(bars)
        error('No bar objects found in %s.', figFile);
    end

    % Case 1:
    % A normal vector bar chart, one Bar object, YData has length 14.
    if numel(bars) == 1
        b = bars(1);

        xCenters = get_bar_xdata(b);
        yValues  = b.YData(:).';

        if isempty(xCenters)
            xCenters = 1:numel(yValues);
        end

        [xCenters, order] = sort(xCenters(:).');
        yValues = yValues(order);

        return;
    end

    % Case 2:
    % Multiple Bar objects, possibly one bar object per plotted bar.
    % Collect all individual bar centers and values.
    xs = [];
    ys = [];

    for k = 1:numel(bars)
        b = bars(k);

        xk = get_bar_xdata(b);
        yk = b.YData(:).';

        if isempty(xk)
            xk = 1:numel(yk);
        end

        if numel(xk) ~= numel(yk)
            % For grouped bar objects, XData may not directly contain
            % the visual center. Try using XEndPoints if available.
            try
                xk = b.XEndPoints;
            catch
                error('Cannot determine bar x positions in %s.', figFile);
            end
        end

        xs = [xs, xk(:).']; %#ok<AGROW>
        ys = [ys, yk(:).']; %#ok<AGROW>
    end

    [xs, order] = sort(xs);
    ys = ys(order);

    % Merge bars with nearly identical x positions.
    % This should rarely be needed for the original files.
    tol = 1e-6;
    xUnique = [];
    yUnique = [];

    i = 1;
    while i <= numel(xs)
        j = i;
        while j < numel(xs) && abs(xs(j+1) - xs(i)) < tol
            j = j + 1;
        end

        xUnique(end+1) = mean(xs(i:j)); %#ok<AGROW>

        if j == i
            yUnique(end+1) = ys(i); %#ok<AGROW>
        else
            % If multiple bars share the same x center, keep their sum.
            % This branch should not be triggered for ordinary Fig. 12 files.
            yUnique(end+1) = sum(ys(i:j), 'omitnan'); %#ok<AGROW>
        end

        i = j + 1;
    end

    xCenters = xUnique;
    yValues = yUnique;
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

function separatorX = detect_vertical_dashed_separators(ax)
    % Detect vertical dashed separator lines in an axes.

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

        % Must be dashed or dash-dot.
        isDashed = lineStyle == "--" || lineStyle == "-.";

        if ~isDashed
            continue;
        end

        % Must be vertical: x is almost constant and y changes.
        if max(x) - min(x) < 1e-8 && max(y) - min(y) > 1e-8
            separatorX(end+1) = mean(x); %#ok<AGROW>
        end
    end

    % Remove duplicates caused by repeated line handles.
    if ~isempty(separatorX)
        separatorX = unique(round(separatorX, 8));
    end
end

function selected = choose_three_internal_separators(separatorX, xCenters)
    % If more than three dashed vertical lines are detected, select the
    % three most likely separators between the four requirement regions.
    %
    % For 14 step groups, the expected separators are around:
    %   after 2 bars, after 5 bars, after 9 bars
    % which correspond to midpoints:
    %   (x2+x3)/2, (x5+x6)/2, (x9+x10)/2.

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

    % Generic fallback:
    % choose three separators that divide the x-axis into nonempty regions
    % and are approximately evenly distributed.
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

function T = make_long_table(CommCost_all, CompCost_all, AccMetric_all, ...
    reqLabels, uavLabels, maxSteps)

    Requirement = {};
    UAV = {};
    Step = [];
    CommunicationCost = [];
    ComputationCost = [];
    AccuracyMetric = [];

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

                Requirement{end+1, 1} = reqLabels{r}; %#ok<AGROW>
                UAV{end+1, 1} = uavLabels{u}; %#ok<AGROW>
                Step(end+1, 1) = s; %#ok<AGROW>

                CommunicationCost(end+1, 1) = c1; %#ok<AGROW>
                ComputationCost(end+1, 1) = c2; %#ok<AGROW>
                AccuracyMetric(end+1, 1) = c3; %#ok<AGROW>
            end
        end
    end

    T = table(Requirement, UAV, Step, ...
        CommunicationCost, ComputationCost, AccuracyMetric);
end