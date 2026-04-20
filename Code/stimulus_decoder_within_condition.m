%% ============================================================
% MT population stimulus decoder (within-condition)
%
% Purpose:
%   1) build a simultaneous trial x feature matrix from LFP data
%   2) decode session-level binary stimulus identity within each condition
%   3) compare decoding across matched pre/post sessions
%
% Notes:
%   - This script uses true trial alignment across simultaneously recorded
%     channels within a session.
%   - The decoded label is the session-level binary stimulus label stored in
%     dataset(:,4), not a channel-specific preference label.
%   - By default, the analysis restricts to the highest shared nonzero
%     stimulus bins, but this can be changed in the configuration block.
%
% Expected data columns:
%   1  = time (ms)
%   2  = trial index
%   4  = binary stimulus label (0/1)
%   5  = stimulus value
%   6  = stimulus bin
%   11 = behavioral outcome code
%   12 = LFP
%% ============================================================

clear; clc;

%% ---------------------- CONFIGURATION -----------------------
% Set the dataset root to the folder containing the pre/post subfolders.
DATA_ROOT = fullfile('path', 'to', 'dataset');
PRE_SUBDIR = 'pre-inactivation';
POST_SUBDIR = 'post-inactivation';
RESULTS_SUBDIR = 'results_decoder';

PRE_DIR  = fullfile(DATA_ROOT, PRE_SUBDIR);
POST_DIR = fullfile(DATA_ROOT, POST_SUBDIR);
OUT_DIR  = fullfile(DATA_ROOT, RESULTS_SUBDIR);
if ~exist(OUT_DIR, 'dir')
    mkdir(OUT_DIR);
end

% Session matching / channels
MATCH_NCHARS = ;
N_CHANNELS = ;

% Analysis window (ms)
WIN_START_MS = ;
WIN_STOP_MS  = ;

% Frequency bands (Hz)
BAND_NAMES_ALL = {'highgamma'};
BAND_LIMITS_ALL = [70 150];

% Restrict to top N shared nonzero bins. Set [] to use all shared bins.
USE_TOP_N_BINS = ;

% Spectral parameters for Chronux mtspectrumc
SPEC_PARAMS = [];
SPEC_PARAMS.Fs       = ;
SPEC_PARAMS.fpass    = ;
SPEC_PARAMS.pad      = ;
SPEC_PARAMS.tapers   = ;
SPEC_PARAMS.trialave = ;

% Decoder settings
N_REPEATS = ;
K_FOLDS = ;
MIN_TRIALS_PER_CLASS = ;
RNG_SEED = 1;

% Trial selection
OUTCOME_CODE = 1;          % e.g. 1 = correct
OUTCOME_NAME = 'correct';

rng(RNG_SEED);

config = struct();
config.data_root = DATA_ROOT;
config.pre_subdir = PRE_SUBDIR;
config.post_subdir = POST_SUBDIR;
config.results_subdir = RESULTS_SUBDIR;
config.match_nchars = MATCH_NCHARS;
config.n_channels = N_CHANNELS;
config.win_start_ms = WIN_START_MS;
config.win_stop_ms = WIN_STOP_MS;
config.band_names = {BAND_NAMES_ALL{:}};
config.band_limits = BAND_LIMITS_ALL;
config.use_top_n_bins = USE_TOP_N_BINS;
config.spec_params = SPEC_PARAMS;
config.n_repeats = N_REPEATS;
config.k_folds = K_FOLDS;
config.min_trials_per_class = MIN_TRIALS_PER_CLASS;
config.rng_seed = RNG_SEED;
config.outcome_code = OUTCOME_CODE;
config.outcome_name = OUTCOME_NAME;

%% ---------------------- FIND MATCHED SESSIONS ---------------
pre_sess  = get_session_dirs(PRE_DIR);
post_sess = get_session_dirs(POST_DIR);

pre_keys  = session_keys_from_names(pre_sess, MATCH_NCHARS);
post_keys = session_keys_from_names(post_sess, MATCH_NCHARS);

common_keys = intersect(pre_keys, post_keys);
common_keys = sort(common_keys);

fprintf('Found %d matched session families after exclusions.\n', numel(common_keys));

%% ---------------------- MAIN LOOP ---------------------------
summary_rows = struct([]);
all_results  = struct();

for iSess = 1:numel(common_keys)

    sess_key  = common_keys{iSess};
    pre_name  = pre_sess{find(strcmp(pre_keys,  sess_key), 1, 'first')};
    post_name = post_sess{find(strcmp(post_keys, sess_key), 1, 'first')};

    fprintf('\n====================================================\n');
    fprintf('Session family: %s\n', sess_key);
    fprintf('  PRE : %s\n', pre_name);
    fprintf('  POST: %s\n', post_name);

    for iBand = 1:numel(BAND_NAMES_ALL)

        band_name = BAND_NAMES_ALL{iBand};
        band_lim  = BAND_LIMITS_ALL(iBand,:);

        fprintf('  Band: %s [%d %d] Hz\n', band_name, band_lim(1), band_lim(2));

        [Tpre, build_info_pre] = build_session_feature_table_bandavg( ...
            PRE_DIR, pre_name, N_CHANNELS, WIN_START_MS, WIN_STOP_MS, ...
            {band_name}, band_lim, SPEC_PARAMS, exclude_channels_this_session);

        [Tpost, build_info_post] = build_session_feature_table_bandavg( ...
            POST_DIR, post_name, N_CHANNELS, WIN_START_MS, WIN_STOP_MS, ...
            {band_name}, band_lim, SPEC_PARAMS, exclude_channels_this_session);

        if isempty(Tpre) || isempty(Tpost) || height(Tpre) == 0 || height(Tpost) == 0
            warning('Empty feature table for %s in session %s. Skipping band.', band_name, sess_key);
            continue;
        end

        Tpre  = Tpre(Tpre.outcome  == OUTCOME_CODE, :);
        Tpost = Tpost(Tpost.outcome == OUTCOME_CODE, :);

        Tpre  = Tpre(ismember(Tpre.stim_bin,  common_bins), :);
        Tpost = Tpost(ismember(Tpost.stim_bin, common_bins), :);

        Tpre_use  = Tpre(ismember(Tpre.stim_bin,  bins_use), :);
        Tpost_use = Tpost(ismember(Tpost.stim_bin, bins_use), :);

        Tpre_use  = balance_by_bin_and_label(Tpre_use);
        Tpost_use = balance_by_bin_and_label(Tpost_use);

        [Tpre_use, Tpost_use] = match_total_trials_prepost(Tpre_use, Tpost_use);

        fprintf('    PRE  valid channels=%d | intersected trials=%d\n', ...
            build_info_pre.n_valid_channels, build_info_pre.n_common_trials);
        fprintf('    POST valid channels=%d | intersected trials=%d\n', ...
            build_info_post.n_valid_channels, build_info_post.n_common_trials);
        fprintf('    PRE  balanced total=%d | label0=%d | label1=%d\n', ...
            height(Tpre_use), sum(Tpre_use.stim_label==0), sum(Tpre_use.stim_label==1));
        fprintf('    POST balanced total=%d | label0=%d | label1=%d\n', ...
            height(Tpost_use), sum(Tpost_use.stim_label==0), sum(Tpost_use.stim_label==1));

        [res_pre, bin_rows_pre] = run_decoder_with_bin_metrics( ...
            Tpre_use, sess_key, pre_name, 'pre', describe_subset(bins_use, common_bins), ...
            K_FOLDS, N_REPEATS, MIN_TRIALS_PER_CLASS);

        [res_post, bin_rows_post] = run_decoder_with_bin_metrics( ...
            Tpost_use, sess_key, post_name, 'post', describe_subset(bins_use, common_bins), ...
            K_FOLDS, N_REPEATS, MIN_TRIALS_PER_CLASS);

        summary_rows = append_row(summary_rows, pack_summary_row_band(sess_key, pre_name, 'pre', band_name, band_lim, bins_use, res_pre));
        summary_rows = append_row(summary_rows, pack_summary_row_band(sess_key, post_name, 'post', band_name, band_lim, bins_use, res_post));

        if ~isfield(all_results, sess_key)
            all_results.(sess_key) = struct();
        end
        all_results.(sess_key).common_bins = common_bins;
        all_results.(sess_key).bins_used = bins_use;
        all_results.(sess_key).(sprintf('pre_table_%s', band_name)) = Tpre_use;
        all_results.(sess_key).(sprintf('post_table_%s', band_name)) = Tpost_use;
        all_results.(sess_key).(sprintf('pre_result_%s', band_name)) = res_pre;
        all_results.(sess_key).(sprintf('post_result_%s', band_name)) = res_post;
        all_results.(sess_key).(sprintf('pre_binrows_%s', band_name)) = bin_rows_pre;
        all_results.(sess_key).(sprintf('post_binrows_%s', band_name)) = bin_rows_post;
    end
end

%% ---------------------- SAVE OUTPUTS ------------------------
summary_table = struct2table(summary_rows);
summary_csv = fullfile(OUT_DIR, 'decoder_summary.csv');
mat_out     = fullfile(OUT_DIR, 'decoder_results.mat');

writetable(summary_table, summary_csv);
save(mat_out, 'all_results', 'summary_table', 'config', '-v7.3');

fprintf('\nSaved summary CSV:\n%s\n', summary_csv);
fprintf('Saved MAT file:\n%s\n', mat_out);

%% ============================================================
% LOCAL FUNCTIONS
%% ============================================================

function sess_dirs = get_session_dirs(parent_dir)
    d = dir(parent_dir);
    is_good = [d.isdir] & ~ismember({d.name}, {'.','..'}) & ~startsWith({d.name}, '._');
    sess_dirs = {d(is_good).name};
    sess_dirs = sort(sess_dirs);
end

function keys = session_keys_from_names(sess_names, n_chars)
    keys = cell(size(sess_names));
    for i = 1:numel(sess_names)
        name_i = sess_names{i};
        if numel(name_i) < n_chars
            error('Session name "%s" is shorter than MATCH_NCHARS=%d.', name_i, n_chars);
        end
        keys{i} = name_i(1:n_chars);
    end
end

function bins_use = choose_bins(common_bins, n_keep)
    common_bins = sort(common_bins(:));
    if isempty(common_bins)
        bins_use = [];
        return;
    end
    if isempty(n_keep)
        bins_use = common_bins;
        return;
    end
    n_keep = min(n_keep, numel(common_bins));
    bins_use = common_bins(end-n_keep+1:end);
end

function subset_name = describe_subset(bins_use, common_bins)
    if numel(bins_use) == numel(common_bins) && isequal(sort(bins_use(:)), sort(common_bins(:)))
        subset_name = 'all_shared_bins';
    else
        subset_name = sprintf('top_%d_shared_bins', numel(bins_use));
    end
end

function [T, info] = build_session_feature_table_bandavg(base_dir, sess_name, n_channels, ...
    win_start_ms, win_stop_ms, band_names, band_limits, spec_params, exclude_channels)

    if nargin < 9 || isempty(exclude_channels)
        exclude_channels = [];
    end

    chan_tables = cell(n_channels, 1);
    valid_channels = false(n_channels, 1);
    info = struct();
    info.n_valid_channels = 0;
    info.n_common_trials = 0;
    info.valid_channel_ids = [];

    for ch = 1:n_channels
        if ismember(ch, exclude_channels)
            continue;
        end

        matfile = fullfile(base_dir, sess_name, sprintf('%s%dNL.mat', sess_name, ch));
        if ~exist(matfile, 'file')
            continue;
        end

        S = load(matfile);
        if ~isfield(S, 'dataset')
            continue;
        end

        chanT = extract_channel_trial_features_bandavg( ...
            S.dataset, win_start_ms, win_stop_ms, band_names, band_limits, spec_params);

        if isempty(chanT) || height(chanT) == 0
            continue;
        end

        chan_tables{ch} = chanT;
        valid_channels(ch) = true;
    end

    if ~any(valid_channels)
        T = table();
        return;
    end

    valid_chan_idx = find(valid_channels);
    common_trials = chan_tables{valid_chan_idx(1)}.trial;
    for ii = 2:numel(valid_chan_idx)
        common_trials = intersect(common_trials, chan_tables{valid_chan_idx(ii)}.trial);
    end

    if isempty(common_trials)
        T = table();
        return;
    end

    T0 = chan_tables{valid_chan_idx(1)};
    T0 = T0(ismember(T0.trial, common_trials), :);
    T0 = sortrows(T0, 'trial');
    T = T0(:, {'trial', 'stim_label', 'stim_level', 'stim_bin', 'outcome'});

    for ii = 1:numel(valid_chan_idx)
        ch = valid_chan_idx(ii);
        Tc = chan_tables{ch};
        Tc = Tc(ismember(Tc.trial, common_trials), :);
        Tc = sortrows(Tc, 'trial');

        for b = 1:numel(band_names)
            var_in  = sprintf('%s_power', band_names{b});
            var_out = sprintf('ch%02d_%s', ch, band_names{b});
            T.(var_out) = Tc.(var_in);
        end
    end

    T = T(T.stim_level ~= 0, :);

    info.n_valid_channels = numel(valid_chan_idx);
    info.n_common_trials = numel(common_trials);
    info.valid_channel_ids = valid_chan_idx;
end

function chanT = extract_channel_trial_features_bandavg(s, win_start_ms, win_stop_ms, ...
    band_names, band_limits, spec_params)

    meta = unique(s(:, [2 4 5 6 11]), 'rows', 'stable');
    ntr = size(meta, 1);

    if ntr == 0
        chanT = table();
        return;
    end

    if size(band_limits,1) ~= numel(band_names)
        error('band_limits and band_names size mismatch.');
    end

    nBands = size(band_limits, 1);

    X = nan(ntr, nBands);
    trial_vec = nan(ntr,1);
    stim_vec  = nan(ntr,1);
    cohv_vec  = nan(ntr,1);
    cohb_vec  = nan(ntr,1);
    out_vec   = nan(ntr,1);

    for i = 1:ntr
        trial_num = meta(i,1);
        stim_lab  = meta(i,2);
        coh_val   = meta(i,3);
        coh_bin   = meta(i,4);
        outcome   = meta(i,5);

        idx = (s(:,2)==trial_num) & (s(:,1)>=win_start_ms) & (s(:,1)<win_stop_ms);
        lfp = s(idx,12);
        if isempty(lfp)
            continue;
        end

        lfp = lfp(:);
        [Sspec, f] = mtspectrumc(lfp, spec_params);

        if isempty(Sspec) || isempty(f)
            continue;
        end

        logS = log10(Sspec);
        band_vals = nan(1, nBands);
        for b = 1:nBands
            use = (f >= band_limits(b,1)) & (f < band_limits(b,2));
            if band_limits(b,2) == max(band_limits(:,2))
                use = (f >= band_limits(b,1)) & (f <= band_limits(b,2));
            end
            if any(use)
                band_vals(b) = mean(logS(use), 'omitnan');
            end
        end

        if any(~isfinite(band_vals))
            continue;
        end

        trial_vec(i) = trial_num;
        stim_vec(i)  = stim_lab;
        cohv_vec(i)  = coh_val;
        cohb_vec(i)  = coh_bin;
        out_vec(i)   = outcome;
        X(i,:)       = band_vals;
    end

    good = ~(isnan(trial_vec) | isnan(stim_vec) | isnan(cohv_vec) | isnan(cohb_vec) | isnan(out_vec));
    good = good & all(isfinite(X),2);

    chanT = table(trial_vec(good), stim_vec(good), cohv_vec(good), cohb_vec(good), out_vec(good), ...
        'VariableNames', {'trial','stim_label','stim_level','stim_bin','outcome'});

    for b = 1:nBands
        chanT.(sprintf('%s_power', band_names{b})) = X(good,b);
    end
end

function Tbal = balance_by_bin_and_label(T)
    if isempty(T) || height(T)==0
        Tbal = T;
        return;
    end

    bins = unique(T.stim_bin);
    keep_idx = false(height(T),1);

    for b = bins(:)'
        idx_b = find(T.stim_bin == b);
        Tb = T(idx_b, :);

        idx0 = idx_b(Tb.stim_label == 0);
        idx1 = idx_b(Tb.stim_label == 1);

        n_keep = min(numel(idx0), numel(idx1));
        if n_keep < 1
            continue;
        end

        idx0_keep = idx0(randperm(numel(idx0), n_keep));
        idx1_keep = idx1(randperm(numel(idx1), n_keep));

        keep_idx(idx0_keep) = true;
        keep_idx(idx1_keep) = true;
    end

    Tbal = T(keep_idx, :);
    Tbal = sortrows(Tbal, {'stim_bin', 'trial'});
end

function [Tpre_out, Tpost_out] = match_total_trials_prepost(Tpre_in, Tpost_in)
    Tpre_out = Tpre_in;
    Tpost_out = Tpost_in;

    if isempty(Tpre_in) || isempty(Tpost_in) || height(Tpre_in)==0 || height(Tpost_in)==0
        return;
    end

    n_pre = height(Tpre_in);
    n_post = height(Tpost_in);
    n_match = min(n_pre, n_post);

    if n_pre > n_match
        keep_pre = randperm(n_pre, n_match);
        Tpre_out = Tpre_in(keep_pre, :);
    end

    if n_post > n_match
        keep_post = randperm(n_post, n_match);
        Tpost_out = Tpost_in(keep_post, :);
    end

    Tpre_out  = sortrows(Tpre_out,  {'stim_bin', 'trial'});
    Tpost_out = sortrows(Tpost_out, {'stim_bin', 'trial'});
end

function [res, bin_rows] = run_decoder_with_bin_metrics(T, sess_key, sess_name, condition, subset_name, ...
    K_folds, N_repeats, min_trials_per_class)

    bin_rows = struct([]);
    res = make_empty_result(sess_key, sess_name, condition, subset_name);

    if isempty(T) || height(T)==0
        res.status = "no_trials";
        return;
    end

    feature_names = T.Properties.VariableNames;
    is_feat = startsWith(feature_names, 'ch');
    X = table2array(T(:, is_feat));
    y = T.stim_label;

    good = all(isfinite(X),2) & isfinite(y);
    X = X(good,:);
    y = y(good);
    T = T(good,:);

    n0 = sum(y==0);
    n1 = sum(y==1);

    res.n_trials_total = numel(y);
    res.n_trials_label0 = n0;
    res.n_trials_label1 = n1;
    res.n_features = size(X,2);
    res.n_stim_bins = numel(unique(T.stim_bin));

    if min(n0,n1) < min_trials_per_class
        res.status = "too_few_trials";
        return;
    end

    K_eff = min([K_folds, n0, n1]);
    if K_eff < 2
        res.status = "too_few_trials";
        return;
    end

    lambda_grid = logspace(-4, 2, 13);

    aucs = nan(N_repeats,1);
    accs = nan(N_repeats,1);
    chosen_lambda = nan(N_repeats, K_eff);

    bins = unique(T.stim_bin);
    bin_acc_mat = nan(N_repeats, numel(bins));
    bin_auc_mat = nan(N_repeats, numel(bins));
    bin_n_mat   = nan(N_repeats, numel(bins));
    bin_cohval  = nan(1, numel(bins));

    for ib = 1:numel(bins)
        b = bins(ib);
        vals = unique(T.stim_level(T.stim_bin == b));
        if numel(vals)==1
            bin_cohval(ib) = vals;
        else
            bin_cohval(ib) = mean(vals);
        end
    end

    for r = 1:N_repeats
        cvp = cvpartition(y, 'KFold', K_eff);

        y_all = [];
        pred_all = [];
        score_all = [];
        bin_all = [];

        for k = 1:K_eff
            tr = training(cvp, k);
            te = test(cvp, k);

            Xtr = X(tr,:);
            Xte = X(te,:);
            ytr = y(tr);
            yte = y(te);

            ctr = median(Xtr,1);
            sca = iqr(Xtr,1);
            sca(sca==0) = 1;

            Xtrz = (Xtr - ctr) ./ sca;
            Xtez = (Xte - ctr) ./ sca;

            best_lambda = select_best_lambda_innercv(Xtrz, ytr, lambda_grid);
            chosen_lambda(r,k) = best_lambda;

            mdl = fitclinear(Xtrz, ytr, ...
                'Learner', 'logistic', ...
                'Regularization', 'ridge', ...
                'Lambda', best_lambda, ...
                'Solver', 'lbfgs', ...
                'ClassNames', [0 1]);

            [ypred, score] = predict(mdl, Xtez);

            y_all     = [y_all; yte]; %#ok<AGROW>
            pred_all  = [pred_all; ypred]; %#ok<AGROW>
            score_all = [score_all; score(:,2)]; %#ok<AGROW>
            bin_all   = [bin_all; T.stim_bin(te)]; %#ok<AGROW>
        end

        accs(r) = mean(pred_all == y_all);
        aucs(r) = safe_auc(y_all, score_all);

        for ib = 1:numel(bins)
            idx = (bin_all == bins(ib));
            if sum(idx) < 2
                continue;
            end

            bin_n_mat(r, ib) = sum(idx);
            bin_acc_mat(r, ib) = mean(pred_all(idx) == y_all(idx));
            bin_auc_mat(r, ib) = safe_auc(y_all(idx), score_all(idx));
        end
    end

    mean_bin_acc = mean(bin_acc_mat, 1, 'omitnan');
    sem_bin_acc  = std(bin_acc_mat, [], 1, 'omitnan') ./ sqrt(sum(~isnan(bin_acc_mat),1));

    [thr50, slope, fit_status] = fit_neurometric_curve(bin_cohval, mean_bin_acc);

    res.status = "ok";
    res.k_folds = K_eff;
    res.n_repeats = N_repeats;
    res.mean_accuracy = mean(accs, 'omitnan');
    res.all_acc = accs;
    res.sem_accuracy  = std(accs, 'omitnan') / sqrt(sum(~isnan(accs)));
    res.mean_auc      = mean(aucs, 'omitnan');
    res.sem_auc       = std(aucs, 'omitnan') / sqrt(sum(~isnan(aucs)));
    res.neurometric_threshold50 = thr50;
    res.neurometric_slope = slope;
    res.neurometric_fit_status = fit_status;
    res.mean_best_lambda = mean(chosen_lambda(:), 'omitnan');
    res.median_best_lambda = median(chosen_lambda(:), 'omitnan');

    for ib = 1:numel(bins)
        br = struct();
        br.session_key = sess_key;
        br.session_name = sess_name;
        br.condition = condition;
        br.subset = subset_name;
        br.stim_bin = bins(ib);
        br.stim_level = bin_cohval(ib);
        br.mean_accuracy = mean_bin_acc(ib);
        br.sem_accuracy = sem_bin_acc(ib);
        br.mean_auc = mean(bin_auc_mat(:,ib), 'omitnan');
        br.sem_auc = std(bin_auc_mat(:,ib), [], 'omitnan') / sqrt(sum(~isnan(bin_auc_mat(:,ib))));
        br.mean_n = mean(bin_n_mat(:,ib), 'omitnan');

        bin_rows = append_row(bin_rows, br);
    end
end

function auc = safe_auc(y, score_vec)
    auc = NaN;
    if numel(y) < 2 || numel(unique(y)) < 2 || isempty(score_vec) || numel(score_vec) ~= numel(y)
        return;
    end
    try
        [~,~,~,auc] = perfcurve(y, score_vec, 1);
    catch
        auc = NaN;
    end
end

function best_lambda = select_best_lambda_innercv(Xtrz, ytr, lambda_grid)
    n0 = sum(ytr == 0);
    n1 = sum(ytr == 1);

    K_inner = min([4, n0, n1]);
    if K_inner < 2
        best_lambda = 1e-3;
        return;
    end

    cvp_inner = cvpartition(ytr, 'KFold', K_inner);
    mean_acc_per_lambda = nan(numel(lambda_grid), 1);

    for iLam = 1:numel(lambda_grid)
        lam = lambda_grid(iLam);
        acc_inner = nan(K_inner,1);

        for k = 1:K_inner
            tr2 = training(cvp_inner, k);
            te2 = test(cvp_inner, k);

            Xtr2 = Xtrz(tr2,:);
            Xte2 = Xtrz(te2,:);
            ytr2 = ytr(tr2);
            yte2 = ytr(te2);

            mdl = fitclinear(Xtr2, ytr2, ...
                'Learner', 'logistic', ...
                'Regularization', 'ridge', ...
                'Lambda', lam, ...
                'Solver', 'lbfgs', ...
                'ClassNames', [0 1]);

            ypred2 = predict(mdl, Xte2);
            acc_inner(k) = mean(ypred2 == yte2);
        end

        mean_acc_per_lambda(iLam) = mean(acc_inner, 'omitnan');
    end

    best_idx = find(mean_acc_per_lambda == max(mean_acc_per_lambda, [], 'omitnan'), 1, 'first');
    best_lambda = lambda_grid(best_idx);
end

function [thr50, slope, fit_status] = fit_neurometric_curve(x, y)
    thr50 = NaN;
    slope = NaN;
    fit_status = "not_fit";

    good = isfinite(x) & isfinite(y);
    x = x(good);
    y = y(good);

    if numel(x) < 3
        return;
    end

    y = min(max(y, 0.5001), 0.999);

    f = @(p,xx) 0.5 + 0.5 ./ (1 + exp(-(xx - p(1)) ./ p(2)));
    p0 = [median(x), max(std(x), 1)];
    obj = @(p) sum((y - f(p,x)).^2);

    try
        p = fminsearch(obj, p0, optimset('Display','off'));
        thr50 = p(1);
        slope = p(2);
        fit_status = "ok";
    catch
        fit_status = "fit_failed";
    end
end

function row = pack_summary_row_band(sess_key, sess_name, condition, band_name, band_lim, bins_used, res)
    row = struct();
    row.session_key = sess_key;
    row.session_name = sess_name;
    row.condition = condition;
    row.band_name = band_name;
    row.band_fmin = band_lim(1);
    row.band_fmax = band_lim(2);
    row.bins_used = mat2str(bins_used');

    row.status = res.status;
    row.n_trials = res.n_trials_total;
    row.n_label0 = res.n_trials_label0;
    row.n_label1 = res.n_trials_label1;
    row.n_features = res.n_features;

    row.mean_auc = res.mean_auc;
    row.sem_auc = res.sem_auc;
    row.mean_accuracy = res.mean_accuracy;
    row.sem_accuracy = res.sem_accuracy;

    row.threshold50 = res.neurometric_threshold50;
    row.slope = res.neurometric_slope;
    row.fit_status = res.neurometric_fit_status;

    row.mean_best_lambda = res.mean_best_lambda;
    row.median_best_lambda = res.median_best_lambda;
end

function res = make_empty_result(sess_key, sess_name, condition, subset_name)
    res = struct();
    res.session_key = sess_key;
    res.session_name = sess_name;
    res.condition = condition;
    res.subset = subset_name;
    res.status = "";
    res.n_trials_total = NaN;
    res.n_trials_label0 = NaN;
    res.n_trials_label1 = NaN;
    res.n_features = NaN;
    res.n_stim_bins = NaN;
    res.k_folds = NaN;
    res.n_repeats = NaN;
    res.mean_accuracy = NaN;
    res.sem_accuracy = NaN;
    res.mean_auc = NaN;
    res.sem_auc = NaN;
    res.neurometric_threshold50 = NaN;
    res.neurometric_slope = NaN;
    res.neurometric_fit_status = "";
    res.mean_best_lambda = NaN;
    res.median_best_lambda = NaN;
    res.all_acc = [];
end

function S = append_row(S, row)
    if isempty(S)
        S = row;
        S = S(:);
    else
        S = [S(:); row];
    end
end
