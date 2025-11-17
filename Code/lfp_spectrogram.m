function [S_db, t, f, out] = lfp_spectrogram(lfp, Fs, movingwin, varargin)
% lfp_spectrogram  Chronux time-frequency analysis with baseline correction.
%
% Syntax
%   [S_db, t, f, out] = lfp_spectrogram(lfp, Fs, movingwin, 'Name',Value,...)
%
% Inputs
%   lfp       : [T x N] LFP matrix (time x trials/channels)
%   Fs        : sampling rate (Hz)
%   movingwin : [window step] in seconds, e.g., [0.2 0.03]
%
% Name–Value Pairs (optional)
%   'Fpass'         : [fmin fmax], default [1 150]
%   'Pad'           : pad factor, default 2
%   'Tapers'        : [W T p], default [10 0.2 2]
%   'TrialAve'      : logical, average across columns, default true
%   'Notch60'       : logical, apply 60 Hz notch, default true
%   'BaselineBins'  : vector of time-bin indices (on t) to average for baseline; default [] (no baseline)
%   'BaselineType'  : 'ratio' (10*log10(S./base)) or 'sub' (10*log10(S)-10*log10(base)), default 'ratio'
%   'Plot'          : logical, plot heatmap, default true
%   'CLim'          : [cmin cmax] for color axis, default []
%   'Colormap'      : e.g., bone, parula, turbo; default parula
%   'Title'         : char, default 'Spectrogram'
%
% Outputs
%   S_db   : spectrogram in dB (baseline-corrected if BaselineBins provided)
%   t, f   : time (s) and frequency (Hz) vectors from Chronux
%   out    : struct with fields params, baseline_db (if used)
%
% Requires: Chronux toolbox.

% -------- Parse inputs
p = inputParser;
p.addParameter('Fpass', [1 150]);
p.addParameter('Pad', 2);
p.addParameter('Tapers', [10 0.2 2]);
p.addParameter('TrialAve', true);
p.addParameter('Notch60', true);
p.addParameter('BaselineBins', []);
p.addParameter('BaselineType', 'ratio'); % 'ratio' or 'sub'
p.addParameter('Plot', true);
p.addParameter('CLim', []);
p.addParameter('Colormap', 'parula');
p.addParameter('Title', 'Spectrogram');
p.parse(varargin{:});
opt = p.Results;

% -------- Checks
assert(isnumeric(lfp) && ndims(lfp)==2, 'lfp must be [T x N].');
assert(numel(movingwin)==2, 'movingwin must be [window step] in seconds.');

% -------- Optional 60 Hz notch
if opt.Notch60
    lfp = notch60(lfp, Fs);
end

% -------- Chronux params
params = [];
params.Fs      = Fs;
params.fpass   = opt.Fpass;
params.pad     = opt.Pad;
params.tapers  = opt.Tapers;
params.trialave= double(opt.TrialAve);

% -------- Spectrogram
[S_lin, t, f] = mtspecgramc(lfp, movingwin, params);   % S_lin: [timebins x freqs]
S_db_raw = 10*log10(S_lin);

% -------- Baseline correction (optional)
baseline_db = [];
if ~isempty(opt.BaselineBins)
    bins = opt.BaselineBins(:);
    bins = bins(bins>=1 & bins<=size(S_lin,1));
    if isempty(bins)
        warning('BaselineBins out of range; skipping baseline.');
        S_db = S_db_raw;
    else
        base_lin = mean(S_lin(bins, :), 1, 'omitnan');  % [1 x F]
        switch lower(opt.BaselineType)
            case 'ratio'
                S_db = 10*log10( bsxfun(@rdivide, S_lin, base_lin) );
            case 'sub'
                S_db = S_db_raw - 10*log10(base_lin);
            otherwise
                error('BaselineType must be ''ratio'' or ''sub''.');
        end
        baseline_db = 10*log10(base_lin);
    end
else
    S_db = S_db_raw;
end

out.params = params;
out.baseline_db = baseline_db;

% -------- Plot
if opt.Plot
    figure;
    % plot_matrix expects [time x freq]; Chronux’s plot_matrix can be used,
    % but here we use imagesc for neutrality and full control.
    imagesc(t*1000, f, S_db'); axis xy;
    xlabel('Time (ms)'); ylabel('Frequency (Hz)');
    title(opt.Title);
    cb = colorbar; cb.Label.String = 'Power (dB)';
    try, colormap(opt.Colormap); catch, colormap(parula); end
    if ~isempty(opt.CLim), caxis(opt.CLim); end
    set(gca,'FontSize',12);
end
end

% ===== helper =====
function x = notch60(x, Fs)
wo = 60/(Fs/2);
bw = wo/35;
[b,a] = iirnotch(wo, bw);
x = filtfilt(b,a,x);
end
