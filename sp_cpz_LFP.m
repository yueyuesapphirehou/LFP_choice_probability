function [subs,c1,c2] = sp_cpz_LFP(s, selcols, selvals, startt, stopt, binsize, stepsize, prefdir)
% compute choice probability for LFP signals in s 
% matrix s should be spikeMatfrom pl2NFile_saccadeTaskLFP.m
% use selcols to select rows that have selvals in corresponding selcols
% Columns:
% 1 = time (ms) relative to stim onset
% 2 = trial number
% 4 = direction bin
% 6 = coherence bin for dots
% 10 = contrast bin for gratings
% 11 = trial outcome (1 = correct, 2 = failed)

[m,ch] = sp_psth_LFP(s, selcols, selvals, startt, stopt, binsize, stepsize,prefdir);

SUBS = 25; % number of times to subsample from trials
MINTR = 5; % minimal number of trials per choice

numbins = floor((stopt - startt-binsize) / stepsize)+1;

% select relevant trials
g=find(ch==1);
c1 = m(g,:,:);
g=find(ch==2);
c2 = m(g,:,:);

numc1=length(c1(:,1)); 
numc2=length(c2(:,1)); 

if numc1<MINTR || numc2 <MINTR
    subs = [];
    fprintf('not enough trials')
    return; %not enough trials
end
    % re-sampling to balance the # of trials for
    % two choices
subs = [];
    for k = 1:SUBS
      tempc1=c1;
      tempc2=c2;
      if numc1>numc2 
        tempc1=c1(unidrnd(numc1,1,numc2),:,:);
      end
      if numc2>numc1
        tempc2=c2(unidrnd(numc2,1,numc1),:,:);
      end

      % NEW: robust scaling to normalize PSD
      median1 = median(tempc1(:));
      iqr1 = iqr(tempc1(:));
      choice1_scaled = (tempc1 - median1) / iqr1;

      median2 = median(tempc2(:));
      iqr2 = iqr(tempc2(:));
      choice2_scaled = (tempc2 - median2) / iqr2;

      tempc1_all = reshape(choice1_scaled, size(tempc1));
      tempc2_all = reshape(choice2_scaled, size(tempc2));

        for j = 1:numbins
            for b=1:306 %numbands[hardcode from sp_psth_LFPn.m]
                if sum(diff(unique([tempc2_all(:,j,b);tempc1_all(:,j,b)])))==0 
                    subs(k,j,b)=0.5;
                else
                    rocdata=roc_curve_LFPn(tempc2_all(:,j,b)',tempc1_all(:,j,b)',0,0); %class 1=null, class 2= preferred
                    subs(k,j,b)=rocdata.param.AROC;
                end
            end
        end
    end
    subs=squeeze(mean(subs,1));
return;