# LFP_choice_probability

This repository contains analysis code for studying how local field potentials (LFPs) in primate visual cortex relate to perceptual decisions. The project quantifies choice probability (CP) from frequency-resolved LFP power and compares pre- and post-inactivation conditions to dissociate sensory and non-sensory contributions to decision-making.

# Overview

The algorithms included in this repository investigate trial-to-trial variability in neuronal population activity and its relationship to visual perceptual choices.

[UNDER REARRANGEMENT...]

# Source Data:

1. **individual monkey CP values across frequency bands** are formatted as "freqband_mky.csv"
   
2. **area-wise CP values across frequency bands** are formatted as "freqband_areaname.csv"

# Methods & Scripts:

0. Weilbul behavioral psychometric curve fit (MATLAB)

**plt_psychometric.m** — model fit monkey-wise behavioral performance and plot its psychometric curve

1. LFP spectrogram and raw signal visualization (MATLAB)

**lfp_plot_raw.m** — plot all trials of raw LFP in the time domain

**lfp_spectrogram.m** — compute and plot time–frequency spectrograms with Chronux

**spk_raster.m** — plot raster plots for spiking activity under one stimulus condition

2. Choice probability (CP) calculation (MATLAB)

**total_cp_LFP.m** — wrapper function to load channel data on each stimulus condition, and compute CP

**sp_psth_LFP.m** — compute LFP power spectra per trial and choice assignment

**sp_cpz_LFPnp.m** — subsample, normalize, and calculate CP using ROC analysis

**sp_psth_LFP_reward.m** — compute LFP power spectra per trial and choice assignment based on the preceeding trial's behavioral outcome

3. Statistical testing (Python)

**[TO CONTINUE]** — Wilcoxon signed-rank (vs. 0.5) and rank-sum (Pre vs Post) tests

4. Visualization for CP analyses (Python)

**plt_mkywise_cp.py** — plot monkey-wise CP values at the defined frequency band (refer to Supplementary Figures 1-3)

**plot_cp_with_sessions** — plot area-wise CP values at the defined frequency band within the probe presentation (refer to Figure 3's left and middle panels)

**plot_aggre_epoch_cp** — plot aggregated CP values across three behavioral epoch at the defined frequency band (refer to Figure 3's right panel)

**plot_reward_history_alphabeta_barplot** — plot CP values based on prior trials' reward conditions (refer to Figure 4)

6. Simulation (Python)

**[TO CONTINUE]**

7. Visualization for simulation (R)

**plot_cp_heatmap.R** — generate CP heatmaps with contour overlays

**plot_cp_bands_epochs.R** — average CP across frequency bands and time epochs, plot with error bars

8. Helper functions (MATLAB)

**re-reference.m** — refer all the raw LFPs to the ones from the outmost channel

**heatmap_smoothness** — smooth noisy heatmaps based on a convolutional algorithm to minimize distortion

# Datasets:
Electrophysiological recordings from macaque visual cortices during a motion discrimination task (the Middle Temporal (MT) area) and a shape matching task (area V4).

# Reference:
The preprint using this repository is available here: https://www.biorxiv.org/content/10.1101/2025.07.29.667496v3

