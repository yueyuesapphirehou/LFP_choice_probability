function [m_r,ch_r, m_n, ch_n, status] = sp_psth_LFP_reward(s, startt, stopt, binsize, stepsize, prefdir, selvals, selcols)
% compute choice probability for LFP signals in ms 
% use selcols to select rows that have selvals in corresponding selcols
% Columns:
% 1 = time (ms) relative to stim onset
% 2 = trial number
% 4 = direction bin
% 6 = coherence bin
% 10 = contrast bin
% 11 = trial outcome (1 = correct, 2 = failed)
% 12 = LFP

temp = [];
for j = 1:length(selvals) 
 g=find(s(:,selcols)==selvals(j));
 temp=[temp; s(g,:)];
end

temp_all = s;

% give the two target choices' values
u = unique(temp(:,4))';
if length(u)==1
    dirs=[u u];
else
    dirs=u(1:2);
end

%MODIFY THE LFP PARAMETERS BELOW
params =[];
params.Fs=1000; % sampling frequency
params.fpass=[1 300]; % frequency range of interest
params.pad=2; % set the pad factor
params.tapers = [10 0.2 2];    % [W T p]
params.trialave=0; % setting this to 0 NOT averages over trials

numbands = 306;%[HARDCODE] based on [*] for preallocation

numbins = floor((stopt - startt-binsize) / stepsize)+1;

validtrials = unique(temp(:, 2)); %valid trial index
numtrials = length(validtrials);

m_r = zeros(numtrials, numbins, numbands);
m_n = zeros(numtrials, numbins, numbands);
ch_r = [];
ch_n = [];

for j = 2:numtrials %current trial

    pre_trial = validtrials(j)-1;
    y = find(temp_all(:, 2) == pre_trial); %for outer loop computation (previous trial)
    if isempty(y) %original dataset not has this trial
        continue
    end
    reward_con = temp_all(y(1),11); %previous trial's reward condition (correct/failed)

    g = find(temp(:, 2) == validtrials(j));  % for outer loop computation

    if reward_con == 1
        label = "rewarded";
        status = 0;

        for k = 1:numbins
            start_idx = startt+(k-1)*stepsize;
            stop_idx = startt+(k-1)*stepsize+binsize-1;
            cursp=(temp(:,2)==validtrials(j))&(temp(:,1)>=start_idx)&(temp(:,1)<=stop_idx);      
            lfp_data = temp(cursp,12); 
            % Calculate multitaper spectrum
            % [S, f] = mtspectrumc(lfp_data, params);%[*]GET THE LENGTH OF F
            [S] = mtspectrumc(lfp_data, params);
            m_r(j, k, :) = S';
        end   

        if  any(((temp(g(1),4)==prefdir) && (temp(g(1),11)==1))) || ((temp(g(1),4)==1-prefdir) && (temp(g(1),11)==2))
            ch_r(j) = 1;
        elseif any(((temp(g(1),4)==prefdir) && (temp(g(1),11)==2))) || ((temp(g(1),4)==1-prefdir) && (temp(g(1),11)==1))
            ch_r(j) = 2;
        end   

    elseif reward_con == 2
        label = "non-rewarded";
        status = 0;
        for k = 1:numbins
            start_idx = startt+(k-1)*stepsize;
            stop_idx = startt+(k-1)*stepsize+binsize-1;
            cursp=(temp(:,2)==validtrials(j))&(temp(:,1)>=start_idx)&(temp(:,1)<=stop_idx);      
            lfp_data = temp(cursp,12); 
            [S] = mtspectrumc(lfp_data, params);
            m_n(j, k, :) = S';
        end   

        if  any(((temp(g(1),4)==prefdir) && (temp(g(1),11)==1))) || ((temp(g(1),4)==1-prefdir) && (temp(g(1),11)==2))
            ch_n(j) = 1;
        elseif any(((temp(g(1),4)==prefdir) && (temp(g(1),11)==2))) || ((temp(g(1),4)==1-prefdir) && (temp(g(1),11)==1))
            ch_n(j) = 2;
        end

    else
        status = 1; % Change status to 1 to indicate the need to skip
        fprintf('not work')
        return; % Early return to skip further processing
    end
end

return;