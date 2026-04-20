%% ============================================================
% Stimulus-axis and residual-space analysis
%
% Purpose:
%   1) define a linear stimulus axis from population decoding
%   2) remove that axis from the feature space
%   3) characterize variance structure in the residual space
%   4) quantify band-wise loading energy on stimulus-aligned and residual
%      dimensions
%
% Notes:
%   - It does not estimate a formal communication subspace or establish a
%     downstream biological readout.
%   - The stimulus axis is defined separately within each condition from a
%     linear decoder fit to the standardized feature matrix.
%
% Expected dataset columns:
%   1  = time (ms)
%   2  = trial index
%   4  = binary stimulus label (0/1)
%   5  = stim level
%   6  = stim bin
%   11 = behavioral outcome code
%   12 = LFP
%% ============================================================

clear; clc;

%% ---------------------- CONFIGURATION -----------------------
DATA_ROOT = fullfile('path', 'to', 'dataset');
PRE_SUBDIR = 'pre-inactivation';
POST_SUBDIR = 'post-inactivation';
RESULTS_SUBDIR = 'results_stimulus_axis';

PRE_DIR  = fullfile(DATA_ROOT, PRE_SUBDIR);
POST_DIR = fullfile(DATA_ROOT, POST_SUBDIR);
OUT_DIR  = fullfile(DATA_ROOT, RESULTS_SUBDIR);
if ~exist(OUT_DIR, 'dir')
    mkdir(OUT_DIR);
end

SESSION_GROUP_LABEL = 'area';
MATCH_NCHARS = ;
CHANNELS = : ;

WIN_START_MS = ;
WIN_STOP_MS  = ;

FEATURE_FMIN = ;
FEATURE_FMAX = ;

% Restrict to these high-evidence bins. Set [] to use all shared nonzero bins.
HIGH_BINS = [];

OUTCOME_CODE = 1;   % e.g. correct trials only

SPEC_PARAMS = [];
SPEC_PARAMS.Fs       = ;
SPEC_PARAMS.fpass    = ;
SPEC_PARAMS.pad      = ;
SPEC_PARAMS.tapers   = ;
SPEC_PARAMS.trialave = ;

K_FOLDS = ;
N_REPEATS = ;
MIN_TRIALS_PER_CLASS = ;
N_RESID_PCS = ;
RNG_SEED = ;

rng(RNG_SEED);

config = struct();
config.data_root = DATA_ROOT;
config.pre_subdir = PRE_SUBDIR;
config.post_subdir = POST_SUBDIR;
config.results_subdir = RESULTS_SUBDIR;
config.session_group_label = SESSION_GROUP_LABEL;
config.match_nchars = MATCH_NCHARS;
config.channels = CHANNELS;
config.win_start_ms = WIN_START_MS;
config.win_stop_ms = WIN_STOP_MS;
config.feature_fmin = FEATURE_FMIN;
config.feature_fmax = FEATURE_FMAX;
config.high_bins = HIGH_BINS;
config.outcome_code = OUTCOME_CODE;
config.spec_params = SPEC_PARAMS;
config.k_folds = K_FOLDS;
config.n_repeats = N_REPEATS;
config.min_trials_per_class = MIN_TRIALS_PER_CLASS;
config.n_resid_pcs = N_RESID_PCS;
config.rng_seed = RNG_SEED;

%% ---------------------- FIND MATCHED SESSIONS ---------------
pre_sess  = get_session_dirs(PRE_DIR);
post_sess = get_session_dirs(POST_DIR);

pre_keys  = session_keys_from_names(pre_sess, MATCH_NCHARS);
post_keys = session_keys_from_names(post_sess, MATCH_NCHARS);

common_keys = intersect(pre_keys, post_keys);
common_keys = sort(common_keys);

fprintf('Found %d matched session families.\n', numel(common_keys));

%% ---------------------- MAIN LOOP ---------------------------
summary_rows = struct([]);
all_results  = struct();

for iSess = 1:numel(common_keys)

    sess_key = common_keys{iSess};
    pre_name  = pre_sess{find(strcmp(pre_keys, sess_key), 1, 'first')};
    post_name = post_sess{find(strcmp(post_keys, sess_key), 1, 'first')};

    fprintf('\n====================================================\n');
    fprintf('Session family: %s (%s)\n', sess_key, SESSION_GROUP_LABEL);
    fprintf('  PRE : %s\n', pre_name);
    fprintf('  POST: %s\n', post_name);

    [Tpre, f_keep, pre_info] = build_mt_session_feature_table_freq( ...
        PRE_DIR, pre_name, CHANNELS, WIN_START_MS, WIN_STOP_MS, ...
        FEATURE_FMIN, FEATURE_FMAX, SPEC_PARAMS);

    [Tpost, f_keep_post, post_info] = build_mt_session_feature_table_freq( ...
        POST_DIR, post_name, CHANNELS, WIN_START_MS, WIN_STOP_MS, ...
        FEATURE_FMIN, FEATURE_FMAX, SPEC_PARAMS);

    if isempty(Tpre) || isempty(Tpost) || height(Tpre)==0 || height(Tpost)==0
        warning('Empty feature table for session %s. Skipping.', sess_key);
        continue;
    end

    if ~isequal(f_keep, f_keep_post)
        error('Frequency axis mismatch between pre and post in session %s.', sess_key);
    end

    Tpre  = Tpre(Tpre.outcome  == OUTCOME_CODE, :);
    Tpost = Tpost(Tpost.outcome == OUTCOME_CODE, :);

    common_bins = intersect(unique(Tpre.coherence_bin), unique(Tpost.coherence_bin));
    common_bins = sort(common_bins(common_bins >= 1));

    if isempty(common_bins)
        warning('No shared nonzero bins for session %s. Skipping.', sess_key);
        continue;
    end

    if isempty(HIGH_BINS)
        bins_use = common_bins;
    else
        bins_use = intersect(HIGH_BINS, common_bins);
    end

    fprintf('  PRE  valid channels=%d | intersected trials=%d\n', ...
        pre_info.n_valid_channels, pre_info.n_common_trials);
    fprintf('  POST valid channels=%d | intersected trials=%d\n', ...
        post_info.n_valid_channels, post_info.n_common_trials);
    fprintf('  Shared bins: %s\n', mat2str(common_bins'));
    fprintf('  Bins used:   %s\n', mat2str(bins_use'));

    Tpre  = Tpre(ismember(Tpre.coherence_bin,  bins_use), :);
    Tpost = Tpost(ismember(Tpost.coherence_bin, bins_use), :);

    Tpre_bal  = balance_by_bin_and_label(Tpre);
    Tpost_bal = balance_by_bin_and_label(Tpost);

    print_label_counts('PRE ', Tpre_bal);
    print_label_counts('POST', Tpost_bal);

    [res_pre, detail_pre] = analyze_one_condition_axis( ...
        Tpre_bal, sess_key, pre_name, SESSION_GROUP_LABEL, 'pre', ...
        K_FOLDS, N_REPEATS, MIN_TRIALS_PER_CLASS, N_RESID_PCS);

    [res_post, detail_post] = analyze_one_condition_axis( ...
        Tpost_bal, sess_key, post_name, SESSION_GROUP_LABEL, 'post', ...
        K_FOLDS, N_REPEATS, MIN_TRIALS_PER_CLASS, N_RESID_PCS);

    summary_rows = append_row(summary_rows, res_pre);
    summary_rows = append_row(summary_rows, res_post);

    if ~isfield(all_results, sess_key)
        all_results.(sess_key) = struct();
    end
    all_results.(sess_key).group_label = SESSION_GROUP_LABEL;
    all_results.(sess_key).frequencies = f_keep;
    all_results.(sess_key).common_bins = common_bins;
    all_results.(sess_key).bins_used = bins_use;
    all_results.(sess_key).pre = detail_pre;
    all_results.(sess_key).post = detail_post;
end

%% ---------------------- SAVE OUTPUTS ------------------------
summary_table = struct2table(summary_rows);
summary_csv = fullfile(OUT_DIR, 'axis_summary.csv');
mat_out     = fullfile(OUT_DIR, 'axis_results.mat');

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

function [T, f_keep, info] = build_mt_session_feature_table_freq(base_dir, sess_name, channels, ...
    win_start_ms, win_stop_ms, fmin, fmax, spec_params)

    chan_tables = cell(numel(channels), 1);
    valid_channels = false(numel(channels),1);
    f_keep = [];

    info = struct();
    info.n_valid_channels = 0;
    info.n_common_trials = 0;
    info.valid_channel_ids = [];

    for ii = 1:numel(channels)
        ch = channels(ii);
        matfile = fullfile(base_dir, sess_name, sprintf('%s%dNL.mat', sess_name, ch));
        if ~exist(matfile, 'file')
            continue;
        end

        S = load(matfile);
        if ~isfield(S, 'DATASET')
            continue;
        end

        [chanT, f_use] = extract_mt_channel_trial_features_freq( ...
            S.DATASET, win_start_ms, win_stop_ms, fmin, fmax, spec_params);

        if isempty(chanT) || height(chanT)==0
            continue;
        end

        if isempty(f_keep)
            f_keep = f_use;
        elseif ~isequal(f_keep, f_use)
            error('Frequency axis mismatch within session %s channel %d.', sess_name, ch);
        end

        chan_tables{ii} = chanT;
        valid_channels(ii) = true;
    end

    if ~any(valid_channels)
        T = table();
        f_keep = [];
        return;
    end

    valid_idx = find(valid_channels);
    common_trials = chan_tables{valid_idx(1)}.trial;
    for ii = 2:numel(valid_idx)
        common_trials = intersect(common_trials, chan_tables{valid_idx(ii)}.trial);
    end

    if isempty(common_trials)
        T = table();
        return;
    end

    T0 = chan_tables{valid_idx(1)};
    T0 = T0(ismember(T0.trial, common_trials), :);
    T0 = sortrows(T0, 'trial');

    T = T0(:, {'trial','stim_label','stim_level','stim_bin','outcome'});
    freq_var_names = compose('f%03d', round(f_keep));

    for ii = 1:numel(valid_idx)
        ch = channels(valid_idx(ii));
        Tc = chan_tables{valid_idx(ii)};
        Tc = Tc(ismember(Tc.trial, common_trials), :);
        Tc = sortrows(Tc, 'trial');

        if ~isequal(T.trial, Tc.trial)
            error('Trial alignment mismatch in session %s channel %d.', sess_name, ch);
        end

        Xc = table2array(Tc(:, startsWith(Tc.Properties.VariableNames, 'f_')));
        for j = 1:size(Xc,2)
            T.(sprintf('ch%02d_%s', ch, freq_var_names{j})) = Xc(:,j);
        end
    end

    T = T(T.stim_level ~= 0, :);

    info.n_valid_channels = numel(valid_idx);
    info.n_common_trials = numel(common_trials);
    info.valid_channel_ids = channels(valid_idx);
end

function [chanT, f_keep] = extract_mt_channel_trial_features_freq(s, win_start_ms, win_stop_ms, ...
    fmin, fmax, spec_params)

    meta = unique(s(:, [2 4 5 6 11]), 'rows', 'stable');
    ntr = size(meta, 1);

    if ntr == 0
        chanT = table();
        f_keep = [];
        return;
    end

    f_keep = [];
    for i = 1:ntr
        idx = (s(:,2)==meta(i,1)) & (s(:,1)>=win_start_ms) & (s(:,1)<win_stop_ms);
        lfp = s(idx,12);
        if ~isempty(lfp)
            [~, f0] = mtspectrumc(lfp, spec_params);
            use = (f0 >= fmin) & (f0 <= fmax);
            f_keep = f0(use);
            break;
        end
    end

    if isempty(f_keep)
        chanT = table();
        return;
    end

    nfreq = numel(f_keep);
    X = nan(ntr, nfreq);

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

        [Sspec, f] = mtspectrumc(lfp, spec_params);
        use = (f >= fmin) & (f <= fmax);
        Sf = log10(Sspec(use));

        if numel(Sf) ~= nfreq
            continue;
        end

        trial_vec(i) = trial_num;
        stim_vec(i)  = stim_lab;
        cohv_vec(i)  = coh_val;
        cohb_vec(i)  = coh_bin;
        out_vec(i)   = outcome;
        X(i,:)       = Sf(:)';
    end

    good = ~(isnan(trial_vec) | isnan(stim_vec) | isnan(cohv_vec) | isnan(cohb_vec) | isnan(out_vec));
    good = good & all(isfinite(X),2);

    chanT = table(trial_vec(good), stim_vec(good), cohv_vec(good), cohb_vec(good), out_vec(good), ...
        'VariableNames', {'trial','stim_label','stim_level','stim_bin','outcome'});

    for j = 1:nfreq
        chanT.(sprintf('f_%03d', round(f_keep(j)))) = X(good,j);
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
    Tbal = sortrows(Tbal, {'coherence_bin','trial'});
end

function print_label_counts(prefix, T)
    if isempty(T) || height(T)==0
        fprintf('  %s no trials\n', prefix);
        return;
    end
    fprintf('  %s total=%d | label0=%d | label1=%d\n', ...
        prefix, height(T), sum(T.stim_label==0), sum(T.stim_label==1));
end

function [res, detail] = analyze_one_condition_axis(T, sess_key, sess_name, group_label, condition, ...
    K_folds, N_repeats, min_trials_per_class, n_resid_pcs)

    res = make_empty_result(sess_key, sess_name, group_label, condition);
    detail = struct();

    if isempty(T) || height(T)==0
        res.status = "no_trials";
        return;
    end

    feat_names = T.Properties.VariableNames;
    is_feat = startsWith(feat_names, 'ch');
    X = table2array(T(:, is_feat));
    y = T.stim_label;

    good = all(isfinite(X),2) & isfinite(y);
    X = X(good,:);
    y = y(good);

    n0 = sum(y==0);
    n1 = sum(y==1);

    res.n_trials = numel(y);
    res.n_label0 = n0;
    res.n_label1 = n1;
    res.n_features = size(X,2);

    if min(n0,n1) < min_trials_per_class
        res.status = "too_few_trials";
        return;
    end

    ctr = median(X,1);
    sca = iqr(X,1);
    sca(sca==0) = 1;
    Xz = (X - ctr) ./ sca;

    [auc_full_cv, auc_resid_cv] = crossval_full_vs_resid_auc(X, y, K_folds, N_repeats, n_resid_pcs);

    mdl = fitclinear(Xz, y, ...
        'Learner', 'logistic', ...
        'Regularization', 'ridge', ...
        'Lambda', 1e-3, ...
        'Solver', 'lbfgs', ...
        'ClassNames', [0 1]);

    beta = mdl.Beta;
    if norm(beta) == 0
        res.status = "zero_beta";
        return;
    end
    stim_axis = beta / norm(beta);

    [coeff, score, latent, ~, explained] = pca(Xz);

    proj_stim = Xz * stim_axis;
    Xresid = Xz - proj_stim * stim_axis';
    [coeff_resid, score_resid, latent_resid, ~, explained_resid] = pca(Xresid);

    feature_info = parse_feature_info(feat_names(is_feat));

    be_stim  = band_energy(stim_axis, feature_info);
    be_pc1   = band_energy(coeff(:,1), feature_info);
    be_pc2   = band_energy(coeff(:,2), feature_info);
    be_res1  = band_energy(coeff_resid(:,1), feature_info);
    be_res2  = band_energy(coeff_resid(:,2), feature_info);

    align_pc1 = abs(dot(stim_axis, coeff(:,1)));
    align_pc2 = abs(dot(stim_axis, coeff(:,2)));
    align_res1 = abs(dot(stim_axis, coeff_resid(:,1)));
    angle_res1_deg = acosd(max(min(align_res1, 1), 0));

    res.status = "ok";
    res.auc_full_cv = auc_full_cv;
    res.auc_resid_cv = auc_resid_cv;
    res.auc_gap = auc_full_cv - auc_resid_cv;

    res.explained_pc1 = explained(1);
    res.explained_pc2 = explained(2);
    res.explained_resid1 = explained_resid(1);
    res.explained_resid2 = explained_resid(2);

    res.align_pc1_to_stimAxis = align_pc1;
    res.align_pc2_to_stimAxis = align_pc2;
    res.align_resid1_to_stimAxis = align_res1;
    res.angle_resid1_deg = angle_res1_deg;

    res.stimAxis_ab = be_stim.ab;
    res.stimAxis_lg = be_stim.lg;
    res.stimAxis_hg = be_stim.hg;

    res.pc1_ab = be_pc1.ab;
    res.pc1_lg = be_pc1.lg;
    res.pc1_hg = be_pc1.hg;

    res.pc2_ab = be_pc2.ab;
    res.pc2_lg = be_pc2.lg;
    res.pc2_hg = be_pc2.hg;

    res.resid1_ab = be_res1.ab;
    res.resid1_lg = be_res1.lg;
    res.resid1_hg = be_res1.hg;

    res.resid2_ab = be_res2.ab;
    res.resid2_lg = be_res2.lg;
    res.resid2_hg = be_res2.hg;

    detail.Xz = Xz;
    detail.y = y;
    detail.mu = mu;
    detail.sd = sd;
    detail.stim_axis = stim_axis;
    detail.proj_stim = proj_stim;
    detail.coeff = coeff;
    detail.score = score;
    detail.latent = latent;
    detail.explained = explained;
    detail.Xresid = Xresid;
    detail.coeff_resid = coeff_resid;
    detail.score_resid = score_resid;
    detail.latent_resid = latent_resid;
    detail.explained_resid = explained_resid;
    detail.feature_info = feature_info;
    detail.band_energy_stimAxis = be_stim;
    detail.band_energy_pc1 = be_pc1;
    detail.band_energy_pc2 = be_pc2;
    detail.band_energy_resid1 = be_res1;
    detail.band_energy_resid2 = be_res2;
    detail.align_pc1_to_stimAxis = align_pc1;
    detail.align_pc2_to_stimAxis = align_pc2;
    detail.align_resid1_to_stimAxis = align_res1;
    detail.angle_resid1_deg = angle_res1_deg;
end

function [auc_full_cv, auc_resid_cv] = crossval_full_vs_resid_auc(X, y, K_folds, N_repeats, n_resid_pcs)
    n0 = sum(y==0);
    n1 = sum(y==1);
    K_eff = min([K_folds, n0, n1]);

    if K_eff < 2
        auc_full_cv = NaN;
        auc_resid_cv = NaN;
        return;
    end

    auc_full = nan(N_repeats,1);
    auc_resid = nan(N_repeats,1);

    for r = 1:N_REPEATS
        cvp = cvpartition(y, 'KFold', K_eff);

        y_all = [];
        score_full_all = [];
        score_resid_all = [];

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

            mdl_full = fitclinear(Xtrz, ytr, ...
                'Learner', 'logistic', ...
                'Regularization', 'ridge', ...
                'Lambda', 1e-3, ...
                'Solver', 'lbfgs', ...
                'ClassNames', [0 1]);

            [~, score_full_te] = predict(mdl_full, Xtez);
            y_all = [y_all; yte];
            score_full_all = [score_full_all; score_full_te(:,2)];

            beta = mdl_full.Beta;
            if norm(beta) == 0
                continue;
            end
            stim_axis = beta / norm(beta);

            Xtr_resid = Xtrz - (Xtrz * stim_axis) * stim_axis';
            Xte_resid = Xtez - (Xtez * stim_axis) * stim_axis';

            [coeff_resid, score_tr_resid, ~, ~, ~, mu_resid] = pca(Xtr_resid);
            k_use = min([n_resid_pcs, size(coeff_resid,2)]);
            if k_use < 1
                continue;
            end

            score_te_resid = (Xte_resid - mu_resid) * coeff_resid(:,1:k_use);

            mdl_resid = fitclinear(score_tr_resid(:,1:k_use), ytr, ...
                'Learner', 'logistic', ...
                'Regularization', 'ridge', ...
                'Lambda', 1e-3, ...
                'Solver', 'lbfgs', ...
                'ClassNames', [0 1]);

            [~, score_resid_te] = predict(mdl_resid, score_te_resid(:,1:k_use));
            score_resid_all = [score_resid_all; score_resid_te(:,2)]; 
        end

        try
            [~,~,~,auc_full(r)] = perfcurve(y_all, score_full_all, 1);
        catch
            auc_full(r) = NaN;
        end

        try
            [~,~,~,auc_resid(r)] = perfcurve(y_all, score_resid_all, 1);
        catch
            auc_resid(r) = NaN;
        end
    end

    auc_full_cv = mean(auc_full, 'omitnan');
    auc_resid_cv = mean(auc_resid, 'omitnan');
end

function info = parse_feature_info(feat_names)
    n = numel(feat_names);
    ch = nan(n,1);
    fr = nan(n,1);

    for i = 1:n
        tok = regexp(feat_names{i}, 'ch(\d+)_f(\d+)', 'tokens', 'once');
        if isempty(tok)
            error('Could not parse feature name: %s', feat_names{i});
        end
        ch(i) = str2double(tok{1});
        fr(i) = str2double(tok{2});
    end

    info = table((1:n)', ch, fr, 'VariableNames', {'idx','channel','freq'});
end

function be = band_energy(w, feature_info)
    e = w(:).^2;
    e_total = sum(e);

    idx_ab = feature_info.freq >= 5  & feature_info.freq < 30; % alpha-beta
    idx_lg = feature_info.freq >= 30 & feature_info.freq < 70; % low gamma
    idx_hg = feature_info.freq >= 70 & feature_info.freq <= 150; % high gamma

    be = struct();
    be.ab = sum(e(idx_ab)) / e_total;
    be.lg = sum(e(idx_lg)) / e_total;
    be.hg = sum(e(idx_hg)) / e_total;
end

function res = make_empty_result(sess_key, sess_name, group_label, condition)
    res = struct();
    res.session_key = sess_key;
    res.session_name = sess_name;
    res.group_label = group_label;
    res.condition = condition;
    res.status = "";

    res.n_trials = NaN;
    res.n_label0 = NaN;
    res.n_label1 = NaN;
    res.n_features = NaN;

    res.auc_full_cv = NaN;
    res.auc_resid_cv = NaN;
    res.auc_gap = NaN;

    res.explained_pc1 = NaN;
    res.explained_pc2 = NaN;
    res.explained_resid1 = NaN;
    res.explained_resid2 = NaN;

    res.align_pc1_to_stimAxis = NaN;
    res.align_pc2_to_stimAxis = NaN;
    res.align_resid1_to_stimAxis = NaN;
    res.angle_resid1_deg = NaN;

    res.stimAxis_ab = NaN;
    res.stimAxis_lg = NaN;
    res.stimAxis_hg = NaN;

    res.pc1_ab = NaN;
    res.pc1_lg = NaN;
    res.pc1_hg = NaN;

    res.pc2_ab = NaN;
    res.pc2_lg = NaN;
    res.pc2_hg = NaN;

    res.resid1_ab = NaN;
    res.resid1_lg = NaN;
    res.resid1_hg = NaN;

    res.resid2_ab = NaN;
    res.resid2_lg = NaN;
    res.resid2_hg = NaN;
end

function S = append_row(S, row)
    if isempty(S)
        S = row;
        S = S(:);
    else
        S = [S(:); row];
    end
end
