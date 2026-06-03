function [subs, c1, c2] = total_cp_LFP(lfile, session, chan, selcols, selvals, startt, stopt, binsize, stepsize, prefdir)
% INPUT:
% lifle = directory of a task folder4LFP that has spike data
% session = task session
% chan = chan number
% selcols = contrast level column
% selvals = interested contrast level(s)
% startt = starting time
% stopt = stopping time 
% binsize = window size
% stepsiz = window step
% prefdir = preferred direction defined by spikes

ts_filename = fullfile(lfile, session, [session '_TrialStructure.mat']);
ts = load(ts_filename);

channel_filename = fullfile(lfile, session, [session num2str(chan) 'NL.mat']);
allras = load(channel_filename);

s=allras.spikeMat;
  
[subs, c1, c2]=sp_cpz_LFP(s, selcols, selvals, startt, stopt, binsize, stepsize, ts, prefdir);

return;
