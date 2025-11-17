%% ------------------------------------------------------------
% Re-reference LFP signals (col 12) to channel 20
% Saves *_ref.mat files with same variable name and structure
% ------------------------------------------------------------
clear; clc;

%% === Correct session path ===
session_dir = 'C:\Path\to\your\session\folder\';

% === Channel info ===
chan_order = [12,11,10,9,24,23,22,21,13,14,15,16,17,18,19,20];  % tip → up
ref_chan   = 20;      % outermost channel
lfp_col    = 12;      % column with LFP signal

% === Load reference signal from channel 20 ===
ref_file = fullfile(session_dir, sprintf('Sig%d_dlfp.mat', ref_chan));
if ~isfile(ref_file)
    error('Reference file not found: %s', ref_file);
end

ref_data = load(ref_file);
ref_varname = fieldnames(ref_data);
ref_mat = ref_data.(ref_varname{1});

if size(ref_mat,2) < lfp_col
    error('Reference channel has only %d columns. Expecting at least %d.', size(ref_mat,2), lfp_col);
end
ref_sig = ref_mat(:, lfp_col);  % column 12 = LFP
fprintf('Loaded reference signal from channel %d, %d samples.\n', ref_chan, length(ref_sig));

% === Process all channels ===
for ch = chan_order
    in_file = fullfile(session_dir, sprintf('Sig%d_dlfp.mat', ch));
    if ~isfile(in_file)
        fprintf('Channel %d missing, skipping.\n', ch);
        continue;
    end

    % Load
    ch_data = load(in_file);
    varname = fieldnames(ch_data);
    ch_mat  = ch_data.(varname{1});

    % Sanity check
    if size(ch_mat,2) < lfp_col || size(ch_mat,1) ~= length(ref_sig)
        warning('Channel %d: size mismatch or insufficient columns. Skipping.', ch);
        continue;
    end

    % Re-reference ONLY column 12
    ch_mat(:, lfp_col) = ch_mat(:, lfp_col) - ref_sig;

    % Save to new file with same variable name
    out_file = fullfile(session_dir, sprintf('Sig%d_dlfp_ref.mat', ch));
    tmp_struct = struct(varname{1}, ch_mat);
    save(out_file, '-struct', 'tmp_struct', '-v7.3');

    fprintf('Channel %d re-referenced and saved as: %s\n', ch, out_file);
end

fprintf('\n All re-referenced files written to:\n%s\n', session_dir);
