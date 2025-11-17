# Overview

This repository contains analysis code and corresponding data for studying how local field potentials (LFPs) in primate visual cortex relate to perceptual decisions. The project quantifies choice probability (CP) from frequency-resolved LFP power and compares pre- and post-inactivation conditions to dissociate causal and non-causal contributions to decision-making.

# Source Data: 

Electrophysiological recordings from macaque visual cortices during a motion discrimination task (the Middle Temporal (MT) area) and a shape matching task (area V4).

1. **individual monkey CP values across frequency bands** are formatted as "FreqName_mkywise.csv"

2. **area-wise CP values across frequency bands** are formatted as "FreqName_AreaName.csv"
   
3. **grand CP values across frequency bands** are formatted as "FreqName_grand.csv"

4. **epoch-wise CP values per each monkey and condition** are formatted as "anova_df_FreqBand.csv" for direct mixed-effects ANOVA
   
5. **frequency-band-averaged CP traces for each monkey (pre vs post inactivation), their SEM curves, and the monkey-wise Wilcoxon results** are formatted as "cpstats_output_FreqName.pkl"
   
6. **raw CP samples (flattened time × frequency × sessions) pooled by cortical area (V4, MT)** are formatted as "cpstats_area_raw_FreqName.pkl"
   
7. **individual monkey's reward history CP values** are formatted as "rewardhistory_MkyName.csv"

# Methods & Scripts:

1. LFP spectrogram and raw signal visualization (MATLAB)

**lfp_plot_raw.m** — plot all trials of raw LFP in the time domain

**lfp_spectrogram.m** — compute and plot time–frequency spectrograms with Chronux

2. Choice probability (CP) calculation (MATLAB)

**total_cp_LFP.m** — wrapper function to load channel data on each stimulus condition, and compute CP

**sp_psth_LFP.m** — compute LFP power spectra per trial and choice assignment

**sp_cpz_LFP.m** — subsample, normalize, and calculate CP using ROC analysis

**sp_psth_LFP_reward.m** — compute LFP power spectra per trial and choice assignment based on the preceeding trial's behavioral outcome

3. Statistical testing (Python)

**stats_wil.py** — Wilcoxon two-sided signed-rank (vs. 0.5) and rank-sum (Pre vs Post) tests

**stats_anova.py** — Mixed ANOVA (epoch × inactivation condition) per frequency band

4. Visualization for CP analyses (Python)

**plt_mkywise_cp.py** — plot monkey-wise CP values at the defined frequency band (refer to Supplementary Figures 1-3)

**plt_area_cp.py** — plot area-wise CP values at the defined frequency band within the probe presentation (refer to Figure 3's left and middle panels)

**plt_aggre_epoch_cp** — plot aggregated CP values across three behavioral epoch at the defined frequency band (refer to Figure 3's right panel)

**plt_reward_history_alphabeta_barplot** — plot CP values based on prior trials' reward conditions (refer to Figure 4)

5. Simulation (Python)

**sim_neurodsp.py** — simulate LFP signals with pre-determined features for pipeline validation (refer to Supplementary Figure 4)

Three kinds of normalized data are included with conventional z-scoring, balanced z-scoring, and robust scaling.

6. Visualization for simulation (R)

**plt_cp_heatmap.R** — generate CP heatmaps with contour overlays

**plt_cp_bands_epochs.R** — average CP across frequency bands and time epochs, plot with error bars

7. Helper functions (MATLAB)

**re-reference.m** — refer all the raw LFPs to the ones from the outermost channel

# Reference:
The preprint using this repository is available here: https://www.biorxiv.org/content/10.1101/2025.07.29.667496v3

