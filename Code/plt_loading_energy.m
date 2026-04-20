%% ============================================================
% Figure 4
%
% Final figure design:
%   Panel A: stimulus discrimination axis band loading
%   Panel B: leading orthogonal null dimension band loading
%
% Styling:
%   - pooled across MT + V4
%   - no monkey colors
%   - filled circles  = before inactivation
%   - open circles    = after inactivation
%   - bars: gray (before), light blue (after)
%   - significance labels: asterisks or n.s. only
%% ============================================================

clear; clc;

%% ---------------------- FILE PATHS --------------------------
csv = ''; % read in csv files outputed from stimulus_axis_residual_pca.m

out_dir = ' ';
if ~exist(out_dir, 'dir')
    mkdir(out_dir);
end

%% ---------------------- USER CHOICE -------------------------
% Choose which non-readout axis to plot:
%   'null1' = leading orthogonal residual axis  [recommended]
%   'pc1'   = dominant variance axis
VAR_AXIS_TO_PLOT = 'null1';

%% ---------------------- STYLE -------------------------------
BAR_BEFORE = [0.72 0.72 0.72];   % gray
BAR_AFTER  = [0.82 0.90 0.98];   % light blue

POINT_FILL = [0 0 0];
POINT_EDGE = [0 0 0];
LINE_COL   = [0.65 0.65 0.65];

MS        = 34;
LW_PAIR   = 0.9;
LW_AXIS   = 1.2;
ERR_LW    = 1.2;
FONT_SZ   = 11;

%% ---------------------- LOAD + PAIR -------------------------
T1 = readtable(csv);
T2 = readtable(csv);
T3 = readtable(csv);
T4 = readtable(csv);

T = [T1; T2; T3; T4];
T = T(strcmp(T.status, 'ok'), :);

Tpre  = sortrows(T(strcmp(T.condition, 'pre'),  :), {'monkey','session_key'});
Tpost = sortrows(T(strcmp(T.condition, 'post'), :), {'monkey','session_key'});

if height(Tpre) ~= height(Tpost)
    error('Pre/post counts do not match.');
end

if ~all(strcmp(Tpre.monkey, Tpost.monkey)) || ~all(strcmp(Tpre.session_key, Tpost.session_key))
    error('Pre/post session pairing mismatch.');
end

n = height(Tpre);

%% ---------------------- EXTRACT DATA ------------------------
% Panel A: stimulus readout axis
pre_stim_lg  = Tpre.stimAxis_lg;
post_stim_lg = Tpost.stimAxis_lg;
pre_stim_hg  = Tpre.stimAxis_hg;
post_stim_hg = Tpost.stimAxis_hg;

% Panel B: chosen non-readout axis
switch lower(VAR_AXIS_TO_PLOT)
    case 'null1'
        pre_var_lg  = Tpre.null1_lg;
        post_var_lg = Tpost.null1_lg;
        pre_var_hg  = Tpre.null1_hg;
        post_var_hg = Tpost.null1_hg;
        panelB_title = 'Leading orthogonal residual axis';
        out_stub = 'pooled_stimulus_axis_null1_summary';
    case 'pc1'
        pre_var_lg  = Tpre.pc1_lg;
        post_var_lg = Tpost.pc1_lg;
        pre_var_hg  = Tpre.pc1_hg;
        post_var_hg = Tpost.pc1_hg;
        panelB_title = 'Dominant variance axis';
        out_stub = 'pooled_stimulus_axis_pc1_summary';
    otherwise
        error('VAR_AXIS_TO_PLOT must be ''null1'' or ''pc1''.');
end

%% ---------------------- STATS -------------------------------
% Stimulus axis: 
pA_before = signrank(pre_stim_hg,  pre_stim_lg,  'tail', 'right');
pA_after  = signrank(post_stim_hg, post_stim_lg, 'tail', 'right');

% Non-readout axis:
pB_before = signrank(pre_var_lg,  pre_var_hg,  'tail', 'right');
pB_after  = signrank(post_var_lg, post_var_hg, 'tail', 'right');

%% ---------------------- FIGURE ------------------------------
fig = figure('Color','w','Position',[120 140 1100 430]);
tl = tiledlayout(1,2,'TileSpacing','compact','Padding','compact');

%% ============================================================
% Panel A: Stimulus readout axis
%% ============================================================
ax1 = nexttile(tl,1); hold(ax1,'on');

xA = [1 2 4 5];
yA = [mean(pre_stim_lg) mean(post_stim_lg) mean(pre_stim_hg) mean(post_stim_hg)];
eA = [sem(pre_stim_lg)  sem(post_stim_lg)  sem(pre_stim_hg)  sem(post_stim_hg)];

bA = bar(ax1, xA, yA, 0.68, 'FaceColor','flat', 'EdgeColor','none');
bA.CData = [BAR_BEFORE; BAR_AFTER; BAR_BEFORE; BAR_AFTER];

errorbar(ax1, xA, yA, eA, 'k', ...
    'LineStyle','none', 'LineWidth', ERR_LW, 'CapSize', 8);

jit = make_jitter(n, 0.06);

% Low gamma pair
for i = 1:n
    plot(ax1, [1+jit(i), 2+jit(i)], [pre_stim_lg(i), post_stim_lg(i)], '-', ...
        'Color', LINE_COL, 'LineWidth', LW_PAIR);
end
scatter(ax1, 1 + jit, pre_stim_lg,  MS, 'o', ...
    'MarkerFaceColor', POINT_FILL, 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.0);
scatter(ax1, 2 + jit, post_stim_lg, MS, 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.2);

% High gamma pair
for i = 1:n
    plot(ax1, [4+jit(i), 5+jit(i)], [pre_stim_hg(i), post_stim_hg(i)], '-', ...
        'Color', LINE_COL, 'LineWidth', LW_PAIR);
end
scatter(ax1, 4 + jit, pre_stim_hg,  MS, 'o', ...
    'MarkerFaceColor', POINT_FILL, 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.0);
scatter(ax1, 5 + jit, post_stim_hg, MS, 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.2);

% Significance annotations
add_sig(ax1, 1, 4, 0.80, sig_label(pA_before));
add_sig(ax1, 2, 5, 0.86, sig_label(pA_after));

xlim(ax1, [0.35 5.65]);
ylim(ax1, [0 0.95]);
xticks(ax1, xA);
xticklabels(ax1, {'Before inactivation','After inactivation', ...
                  'Before inactivation','After inactivation'});
xtickangle(ax1, 25);
ylabel(ax1, 'Band loading energy');
title(ax1, 'Stimulus discrimination axis');

text(ax1, 1.5, 0.02, 'Low gamma',  'HorizontalAlignment','center', 'FontSize',10);
text(ax1, 4.5, 0.02, 'High gamma', 'HorizontalAlignment','center', 'FontSize',10);

text(ax1, -0.18, 1.02, 'A', 'Units','normalized', ...
    'FontWeight','bold', 'FontSize',13);

set(ax1, 'Box','off', 'LineWidth',LW_AXIS, 'FontSize',FONT_SZ);

%% ============================================================
% Panel B: Non-readout axis
%% ============================================================
ax2 = nexttile(tl,2); hold(ax2,'on');

xB = [1 2 4 5];
yB = [mean(pre_var_lg) mean(post_var_lg) mean(pre_var_hg) mean(post_var_hg)];
eB = [sem(pre_var_lg)  sem(post_var_lg)  sem(pre_var_hg)  sem(post_var_hg)];

bB = bar(ax2, xB, yB, 0.68, 'FaceColor','flat', 'EdgeColor','none');
bB.CData = [BAR_BEFORE; BAR_AFTER; BAR_BEFORE; BAR_AFTER];

errorbar(ax2, xB, yB, eB, 'k', ...
    'LineStyle','none', 'LineWidth', ERR_LW, 'CapSize', 8);

% Low gamma pair
for i = 1:n
    plot(ax2, [1+jit(i), 2+jit(i)], [pre_var_lg(i), post_var_lg(i)], '-', ...
        'Color', LINE_COL, 'LineWidth', LW_PAIR);
end
scatter(ax2, 1 + jit, pre_var_lg,  MS, 'o', ...
    'MarkerFaceColor', POINT_FILL, 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.0);
scatter(ax2, 2 + jit, post_var_lg, MS, 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.2);

% High gamma pair
for i = 1:n
    plot(ax2, [4+jit(i), 5+jit(i)], [pre_var_hg(i), post_var_hg(i)], '-', ...
        'Color', LINE_COL, 'LineWidth', LW_PAIR);
end
scatter(ax2, 4 + jit, pre_var_hg,  MS, 'o', ...
    'MarkerFaceColor', POINT_FILL, 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.0);
scatter(ax2, 5 + jit, post_var_hg, MS, 'o', ...
    'MarkerFaceColor', 'w', 'MarkerEdgeColor', POINT_EDGE, 'LineWidth', 1.2);

% Significance annotations
add_sig(ax2, 1, 4, 0.68, sig_label(pB_before));
add_sig(ax2, 2, 5, 0.74, sig_label(pB_after));

xlim(ax2, [0.35 5.65]);
ylim(ax2, [0 0.9]);
xticks(ax2, xB);
xticklabels(ax2, {'Before inactivation','After inactivation', ...
                  'Before inactivation','After inactivation'});
xtickangle(ax2, 25);
ylabel(ax2, 'Band loading energy');
title(ax2, panelB_title);

text(ax2, 1.5, 0.02, 'Low gamma',  'HorizontalAlignment','center', 'FontSize',10);
text(ax2, 4.5, 0.02, 'High gamma', 'HorizontalAlignment','center', 'FontSize',10);

text(ax2, -0.18, 1.02, 'B', 'Units','normalized', ...
    'FontWeight','bold', 'FontSize',13);

set(ax2, 'Box','off', 'LineWidth',LW_AXIS, 'FontSize',FONT_SZ);

%% ---------------------- SAVE -------------------------------
png_file = fullfile(out_dir, [out_stub '.png']);
pdf_file = fullfile(out_dir, [out_stub '.pdf']);

exportgraphics(fig, png_file, 'Resolution', 300);
exportgraphics(fig, pdf_file, 'ContentType', 'vector');

fprintf('\nSaved figure:\n%s\n%s\n', png_file, pdf_file);

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function s = sem(x)
    x = x(:);
    s = std(x, 'omitnan') / sqrt(sum(~isnan(x)));
end

function jit = make_jitter(n, width)
    if n == 1
        jit = 0;
    else
        jit = linspace(-width, width, n)';
    end
end

function add_sig(ax, x1, x2, y, txt)
    yr = ylim(ax);
    h  = 0.02 * (yr(2) - yr(1));
    plot(ax, [x1 x1 x2 x2], [y-h y y y-h], 'k-', 'LineWidth', 1.0);
    text(ax, mean([x1 x2]), y + 0.01*(yr(2)-yr(1)), txt, ...
        'HorizontalAlignment', 'center', ...
        'VerticalAlignment', 'bottom', ...
        'FontSize', 11);
end

function txt = sig_label(p)
    if isnan(p)
        txt = 'n.s.';
    elseif p < 0.001
        txt = '***';
    elseif p < 0.01
        txt = '**';
    elseif p < 0.05
        txt = '*';
    else
        txt = 'n.s.';
    end
end
