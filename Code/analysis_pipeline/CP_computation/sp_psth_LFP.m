function [m,ch] = sp_psth_LFP(s, selcols, selvals, startt, stopt, binsize, stepsize, prefdir)
% compute choice probability for LFP signals in s 
% matrix s should be spikeMatfrom pl2NFile_saccadeTaskLFP.m
% use selcols to select rows that have selvals in corresponding selcols
% Columns:
% 1 = time (ms) relative to stim onset
% 2 = trial number
% 4 = direction bin
% 6 = coherence bin
% 10 = contrast bin
% 11 = trial outcome (1 = correct, 2 = failed)
% 12 = LFP

% select relevant trials by corresponding
% contrast/coherence level
temp = [];
for j = 1:length(selvals) 
 g=find(s(:,selcols)==selvals(j));
 temp=[temp; s(g,:)];
end

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
params.fpass=[1 150]; % frequency range of interest
params.pad=2; % set the pad factor
params.tapers = [10 0.2 2];    % [W T p]
params.trialave=0; % setting this to 0 NOT averages over trials

numbands = 306;%[HARDCODE] based on [*] for preallocation

numbins = floor((stopt - startt-binsize) / stepsize)+1;

validtrials = unique(temp(:, 2)); %valid trial index
numtrials = length(validtrials);%the total number of valid trials

m = zeros(numtrials, numbins, numbands);
ch = [];

for j = 1:numtrials
    g = find(temp(:, 2) == validtrials(j));  % for outer loop computation
    for k = 1:numbins
        start_idx = startt+(k-1)*stepsize;
        stop_idx = startt+(k-1)*stepsize+binsize-1;
        cursp=(temp(:,2)==validtrials(j))&(temp(:,1)>=start_idx)&(temp(:,1)<=stop_idx);      
        lfp_data = temp(cursp,12);  % Extract LFP data for the current time bin
        % Calculate multitaper spectrum
        % [S, f] = mtspectrumc(lfp_data, params);%[*]GET THE LENGTH OF F
        [S, ~] = mtspectrumc(lfp_data, params);
        m(j, k, :) = S';
    end
    
    % MODIFY THE DEFINITION OF CHOICES BELOW
      if (((temp(g(1),11)==1) && (temp(g(1),4)==prefdir)) || ((temp(g(1),11)==2) && (temp(g(1),4)==1-prefdir)))
           ch(j) = 1;
       elseif(((temp(g(1),11)==1) && (temp(g(1),4)==1-prefdir)) || ((temp(g(1),11)==2) && (temp(g(1),4)== prefdir)))
           ch(j) = 2;
       end 
       
end

return;