function auc = roc_curve_LFP(x1, x2)
%COMPUTE_AUC Area under ROC curve for two samples.
%   Inputs:
%       x1 - numeric vector or array for choice/class 1
%       x2 - numeric vector or array for choice/class 2
%
%   Output:
%       auc - scalar AUC / choice probability value in [0, 1]
%
%   Notes:
%       - NaN and Inf values are removed before calculation.
%       - Ties are handled correctly by using MATLAB's tiedrank function
%         when available.
%       - If either input is empty after filtering, auc is returned as NaN.
    x1 = x1(:);
    x2 = x2(:);
    x1 = x1(isfinite(x1));
    x2 = x2(isfinite(x2));

    n1 = numel(x1);
    n2 = numel(x2);

    if n1 == 0 || n2 == 0
        auc = NaN;
        return;
    end

    % Rank all observations together. The sum of ranks for x1 is converted
    % to the Mann-Whitney U statistic, then normalized by n1*n2.
    values = [x1; x2];

    if exist('tiedrank', 'file') == 2
        ranks = tiedrank(values);
    else
        ranks = local_tiedrank(values);
    end

    rank_sum_x1 = sum(ranks(1:n1));
    u1 = rank_sum_x1 - n1 * (n1 + 1) / 2;
    auc = u1 / (n1 * n2);
    auc = max(0, min(1, auc));
end


function ranks = local_tiedrank(values)
    [sorted_values, sort_idx] = sort(values);
    n = numel(values);
    sorted_ranks = zeros(n, 1);

    i = 1;
    while i <= n
        j = i;
        while j < n && sorted_values(j + 1) == sorted_values(i)
            j = j + 1;
        end

        avg_rank = (i + j) / 2;
        sorted_ranks(i:j) = avg_rank;
        i = j + 1;
    end

    ranks = zeros(n, 1);
    ranks(sort_idx) = sorted_ranks;
end
