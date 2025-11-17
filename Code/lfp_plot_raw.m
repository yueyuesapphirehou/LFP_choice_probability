% Purpose: Plot all trials of raw LFP in time domain from a CSV file.
% Assumes the CSV is [time x trials/channels], raw (unfiltered) LFP.
%
% --- Edit these three lines as needed ---
data_file = "C:\path\to\your\lfp_allsess.csv";  % input CSV [T x N]
Fs        = 1000;                               % sampling rate (Hz)
t0_ms     = 0;                                   % time offset in ms (e.g., -300 if your first row is -300 ms)
% ---------------------------------------

X = readmatrix(data_file);      % X: [T x N]
[T, N] = size(X);

t_ms = (0:T-1) / Fs * 1000 + t0_ms;

figure('Color','w'); hold on;
if N > 0
    plot(t_ms, X, 'Color', [0.7 0.7 0.7], 'LineWidth', 0.5);
end

mu = mean(X, 2, 'omitnan');
plot(t_ms, mu, 'k', 'LineWidth', 2);

[~, base] = fileparts(data_file);
title(sprintf('Raw LFP (all trials) — %s', base), 'Interpreter','none');
xlabel('Time (ms)'); ylabel('Amplitude (raw units)');
grid on; box on; xlim([t_ms(1) t_ms(end)]);
set(gca, 'FontSize', 12);

