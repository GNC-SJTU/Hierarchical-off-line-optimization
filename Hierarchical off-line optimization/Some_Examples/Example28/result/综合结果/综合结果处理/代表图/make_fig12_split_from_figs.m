%% make_fig12_split_from_figs.m
% Rebuild Fig. 12 from the original 15 MATLAB .fig files.
% Output: four figures, one for each accuracy requirement.
% Each output figure has three subplots:
%   1) Communication cost
%   2) Computation cost
%   3) Accuracy Metric tr(P)
%
% X-axis order:
%   UAV6, UAV13, UAV14, UAV20, UAV25

clear; clc; close all;

%% User settings
repoZipUrl = "https://github.com/STYSSTTYY/Hierarchical-off-line-optimization/archive/refs/heads/main.zip";

workDir = fullfile(pwd, "fig12_rebuild_work");
repoDir = fullfile(workDir, "Hierarchical-off-line-optimization-main");

srcDir = fullfile(repoDir, ...
    "Hierarchical off-line optimization", ...
    "Some_Examples", ...
    "Example28", ...
    "result", ...
    "综合结果", ...
    "综合结果处理", ...
    "代表图");

outDir = fullfile(pwd, "Fig12_split_outputs");
if ~exist(outDir, "dir")
    mkdir(outDir);
end

uavIDs     = [6, 13, 14, 20, 25];
uavLabels  = {'UAV6','UAV13','UAV14','UAV20','UAV25'};
reqNames   = {'Low','Medium','High','Very High'};

metricSpecs = struct([]);

metricSpecs(1).suffix = "Communication_Cost";
metricSpecs(1).title  = "Communication Cost";
metricSpecs(1).ylabel = "Communication Cost";

metricSpecs(2).suffix = "Computation_Cost";
metricSpecs(2).title  = "Computation Cost";
metricSpecs(2).ylabel = "Computation Cost";

% Original file name still uses Localization_Error.
% In the revised manuscript figure, the displayed name is changed.
metricSpecs(3).suffix = "Localization_Error";
metricSpecs(3).title  = "Accuracy Metric tr(P)";
metricSpecs(3).ylabel = "Accuracy Metric tr(P)";

%% Download repository if needed
if ~exist(srcDir, "dir")
    if ~exist(workDir, "dir")
        mkdir(workDir);
    end

    zipFile = fullfile(workDir, "repo_main.zip");

    fprintf("Downloading repository zip from GitHub...\n");
    websave(zipFile, repoZipUrl);

    fprintf("Unzipping repository...\n");
    unzip(zipFile, workDir);
end

if ~exist(srcDir, "dir")
    error("Source directory not found: %s", srcDir);
end

%% Read all original .fig data
% data{metricIndex, uavIndex}.Y:
%   rows    = accuracy requirements, normally Low / Medium / High / Very High
%   columns = bar series, normally Step 1 / Step 2 / Step 3 / Step 4
data = cell(numel(metricSpecs), numel(uavIDs));

styleRef = [];
legendLabelsRef = {};

for m = 1:numel(metricSpecs)
    for u = 1:numel(uavIDs)
        figName = sprintf("%d_%s.fig", uavIDs(u), metricSpecs(m).suffix);
        figPath = fullfile(srcDir, figName);

        if ~exist(figPath, "file")
            error("Missing source .fig file: %s", figPath);
        end

        S = read_bar_data_from_fig(figPath);
        data{m,u} = S;

        if isempty(styleRef)
            styleRef = S.style;
        end

        if isempty(legendLabelsRef) && ~isempty(S.legendLabels)
            legendLabelsRef = S.legendLabels;
        end
    end
end

%% Determine number of bar series
nSeries = size(data{1,1}.Y, 2);
if isempty(legendLabelsRef)
    legendLabelsRef = arrayfun(@(k) sprintf("Step %d", k), 1:nSeries, "UniformOutput", false);
end

% Use original colors from the first communication-cost figure.
barColors = data{1,1}.colors;
if isempty(barColors)
    barColors = lines(nSeries);
end

if size(barColors, 1) < nSeries
    barColors = repmat(barColors, ceil(nSeries/size(barColors,1)), 1);
    barColors = barColors(1:nSeries, :);
end

%% Build four new figures
for r = 1:numel(reqNames)
    fig = figure("Color", "w", "Units", "inches", "Position", [1 1 12.0 3.5]);

    tl = tiledlayout(fig, 1, 3, ...
        "TileSpacing", "compact", ...
        "Padding", "compact");

    for m = 1:numel(metricSpecs)
        ax = nexttile(tl);
        hold(ax, "on");

        Ynew = nan(numel(uavIDs), nSeries);

        for u = 1:numel(uavIDs)
            Ysrc = data{m,u}.Y;

            if r > size(Ysrc, 1)
                error("Requirement index %d exceeds source data rows in UAV%d %s.", ...
                    r, uavIDs(u), metricSpecs(m).suffix);
            end

            Ynew(u, :) = Ysrc(r, :);
        end

        b = bar(ax, 1:numel(uavIDs), Ynew, "grouped");

        for k = 1:min(numel(b), nSeries)
            b(k).FaceColor = barColors(k, :);
            b(k).EdgeColor = "none";
        end

        set(ax, ...
            "XTick", 1:numel(uavIDs), ...
            "XTickLabel", uavLabels, ...
            "FontName", styleRef.FontName, ...
            "FontSize", styleRef.FontSize, ...
            "LineWidth", styleRef.LineWidth, ...
            "Box", styleRef.Box, ...
            "YGrid", styleRef.YGrid, ...
            "XGrid", "off");

        title(ax, metricSpecs(m).title, ...
            "FontName", styleRef.FontName, ...
            "FontSize", styleRef.FontSize + 1, ...
            "FontWeight", "normal");

        ylabel(ax, metricSpecs(m).ylabel, ...
            "FontName", styleRef.FontName, ...
            "FontSize", styleRef.FontSize);

        xlabel(ax, "");

        xlim(ax, [0.4, numel(uavIDs) + 0.6]);

        if m == 1
            lgd = legend(ax, legendLabelsRef, ...
                "Location", "northoutside", ...
                "Orientation", "horizontal", ...
                "Box", "off");
            lgd.FontName = styleRef.FontName;
            lgd.FontSize = styleRef.FontSize;
        end

        hold(ax, "off");
    end

    sgtitle(tl, sprintf("%s Accuracy Requirement", reqNames{r}), ...
        "FontName", styleRef.FontName, ...
        "FontSize", styleRef.FontSize + 2, ...
        "FontWeight", "normal");

    outBase = sprintf("Fig12_%s_requirement", sanitize_filename(reqNames{r}));

    savefig(fig, fullfile(outDir, outBase + ".fig"));

    exportgraphics(fig, fullfile(outDir, outBase + ".png"), ...
        "Resolution", 600);

    exportgraphics(fig, fullfile(outDir, outBase + ".pdf"), ...
        "ContentType", "vector");

    fprintf("Saved: %s\n", fullfile(outDir, outBase + ".png"));
end

fprintf("\nDone. Output folder:\n%s\n", outDir);

%% Local functions

function S = read_bar_data_from_fig(figPath)
    fig = openfig(figPath, "invisible");

    cleanupObj = onCleanup(@() close(fig));

    ax = find_main_axes(fig);
    bars = findall(ax, "Type", "Bar");

    if isempty(bars)
        error("No bar object found in %s", figPath);
    end

    bars = sort_bar_objects(bars);

    Y = [];
    colors = [];

    for k = 1:numel(bars)
        yk = bars(k).YData;

        if isrow(yk)
            yk = yk(:);
        end

        if isempty(Y)
            Y = yk;
        else
            Y = [Y, yk]; %#ok<AGROW>
        end

        colors = [colors; get_bar_color(bars(k))]; %#ok<AGROW>
    end

    legendLabels = get_legend_labels(fig, bars);

    S.Y = Y;
    S.colors = colors;
    S.legendLabels = legendLabels;
    S.style = get_axes_style(ax);
end

function ax = find_main_axes(fig)
    axs = findall(fig, "Type", "Axes");

    % Remove legend-like or colorbar-like axes if they exist.
    keep = true(size(axs));
    for i = 1:numel(axs)
        tag = string(get(axs(i), "Tag"));
        if contains(lower(tag), "legend") || contains(lower(tag), "colorbar")
            keep(i) = false;
        end
    end
    axs = axs(keep);

    if isempty(axs)
        error("No axes found in figure.");
    end

    % Choose the axes with the largest number of bar objects.
    nBars = zeros(numel(axs), 1);
    for i = 1:numel(axs)
        nBars(i) = numel(findall(axs(i), "Type", "Bar"));
    end

    [~, idx] = max(nBars);
    ax = axs(idx);
end

function bars = sort_bar_objects(bars)
    bars = bars(:);

    try
        offsets = arrayfun(@(h) h.XOffset, bars);
        [~, idx] = sort(offsets, "ascend");
        bars = bars(idx);
    catch
        % findall often returns objects in reverse visual order.
        bars = flipud(bars);
    end
end

function c = get_bar_color(b)
    c = [];

    try
        fc = b.FaceColor;

        if isnumeric(fc) && numel(fc) == 3
            c = fc(:).';
            return;
        end
    catch
    end

    try
        cd = b.CData;
        if isnumeric(cd) && size(cd, 2) == 3
            c = cd(1, :);
            return;
        end
    catch
    end

    c = [0, 0.4470, 0.7410]; % fallback MATLAB default blue
end

function labels = get_legend_labels(fig, bars)
    labels = {};

    lgd = findall(fig, "Type", "Legend");
    if ~isempty(lgd)
        try
            labels = cellstr(lgd(1).String);
        catch
            labels = {};
        end
    end

    if isempty(labels)
        labels = cell(1, numel(bars));
        for k = 1:numel(bars)
            try
                labels{k} = char(bars(k).DisplayName);
            catch
                labels{k} = "";
            end

            if strlength(string(labels{k})) == 0
                labels{k} = sprintf("Step %d", k);
            end
        end
    end
end

function style = get_axes_style(ax)
    style.FontName = get(ax, "FontName");
    style.FontSize = get(ax, "FontSize");
    style.LineWidth = get(ax, "LineWidth");
    style.Box      = get(ax, "Box");
    style.YGrid    = get(ax, "YGrid");

    if isempty(style.FontName)
        style.FontName = "Times New Roman";
    end

    if isempty(style.FontSize) || style.FontSize < 1
        style.FontSize = 9;
    end

    if isempty(style.LineWidth) || style.LineWidth <= 0
        style.LineWidth = 0.75;
    end
end

function name = sanitize_filename(name)
    name = string(name);
    name = strrep(name, " ", "_");
    name = regexprep(name, "[^\w\-]", "");
end