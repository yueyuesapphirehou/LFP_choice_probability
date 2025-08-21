function results = stats_cp_tests(data_before, data_after, freq_range, time_range)
% stats_cp_tests - Statistical testing for CP values before and after manipulation
%
% Usage:
%   results = stats_cp_tests(data_before, data_after, freq_range, time_range)
%
% Inputs:
%   data_before : [time x freq] matrix of CP values (pre-inactivation or pre-condition)
%   data_after  : [time x freq] matrix of CP values (post-inactivation or post-condition)
%   freq_range  : vector of frequency indices to analyze (e.g., 5:30)
%   time_range  : vector of time indices to analyze (e.g., 15:24)
%
% Outputs:
%   results : struct with fields:
%       .avg_before    - mean CP before
%       .std_before    - std CP before
%       .p_before      - Wilcoxon signed-rank test vs. 0.5 (before)
%       .avg_after     - mean CP after
%       .std_after     - std CP after
%       .p_after       - Wilcoxon signed-rank test vs. 0.5 (after)
%       .p_group       - Wilcoxon rank-sum test (before vs. after)
%
% Example:
%   pre  = readmatrix('data_pre.csv');
%   post = readmatrix('data_post.csv');
%   results = stats_cp_tests(pre, post, 5:30, 15:24);

    data_before_trunc = data_before(time_range, freq_range);
    data_after_trunc  = data_after(time_range, freq_range);

    avg_before = mean(data_before_trunc, "all");
    std_before = std(data_before_trunc(:));
    avg_after  = mean(data_after_trunc, "all");
    std_after  = std(data_after_trunc(:));

    % Signed-rank vs. 0.5
    p_before = signrank(data_before_trunc(:), 0.5);
    p_after  = signrank(data_after_trunc(:), 0.5);

    [p_group, ~] = ranksum(data_before_trunc(:), data_after_trunc(:));

    results = struct( ...
        'avg_before', avg_before, ...
        'std_before', std_before, ...
        'p_before', p_before, ...
        'avg_after', avg_after, ...
        'std_after', std_after, ...
        'p_after', p_after, ...
        'p_group', p_group);

    fprintf('\n--- CP Statistical Tests ---\n');
    fprintf('Before: mean = %.4f, std = %.4f, signed-rank p = %.4g\n', avg_before, std_before, p_before);
    fprintf('After : mean = %.4f, std = %.4f, signed-rank p = %.4g\n', avg_after, std_after, p_after);
    fprintf('Group difference (rank-sum): p = %.4g\n', p_group);
    if p_group < 0.05
        fprintf('Result: Significant difference between groups (p < 0.05)\n');
    else
        fprintf('Result: No significant difference between groups (p >= 0.05)\n');
    end
    fprintf('-----------------------------\n');
end
