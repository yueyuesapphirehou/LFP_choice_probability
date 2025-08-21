# LFP_choice_probability

This repository contains analysis code for studying how local field potentials (LFPs) in primate visual cortex relate to perceptual decisions. The project quantifies choice probability (CP) from frequency-resolved LFP power and compares pre- and post-inactivation conditions to dissociate sensory and non-sensory contributions to decision-making.

# Overview

The algorithms included in this repository investigate trial-to-trial variability in neuronal population activity and its relationship to visual perceptual choices.

# Methods & Scripts:

1. LFP spectrogram and raw signal visualization (MATLAB)

**lfp_plot_raw.m** — plot all trials of raw LFP in the time domain

**lfp_spectrogram.m** — compute and plot time–frequency spectrograms with Chronux

2. Choice probability (CP) calculation (MATLAB)

**total_cp_LFP.m** — wrapper function to load trial structure and channel data, and compute CP

**sp_psth_LFP.m** — compute LFP power spectra per trial and choice assignment

**sp_cpz_LFPnp.m** — subsample, normalize, and calculate CP using ROC analysis

3. Statistical testing (MATLAB)

**stats_cp_tests.m** — Wilcoxon signed-rank (vs. 0.5) and rank-sum (Pre vs Post) tests

4. Visualization (R)

**plot_cp_heatmap.R** — generate CP heatmaps with contour overlays

**plot_cp_bands_epochs.R** — average CP across frequency bands and time epochs, plot with error bars

# Datasets:
Electrophysiological recordings from macaque visual cortex during a motion discrimination task.
Raw data are not distributed here; scripts expect trial × time or time × frequency CSV matrices derived from the recordings.

# Reference:
The preprint using this repository is available here: https://www.biorxiv.org/content/10.1101/2025.07.29.667496v3

