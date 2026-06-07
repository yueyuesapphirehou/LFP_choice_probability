# LFP choice probability source data and code

This repository contains source data and custom code for the manuscript:

**Distinct sources of decision-related signals in visual cortex are represented in different local field potential bands**

The most efficient workflow is to use the one-command runner in `Code/figure_generation/`, which regenerates all supported figure panels from the CSV files in `Source_Data/`.

## How to use this one-command runner

From the repository root:

```bash
pip install -r requirements.txt
cd Code/figure_generation
python run_all_figures.py
```

This runs all figure-generation scripts and writes regenerated PDFs and PNGs to:

```text
Output/generated_figures/
```

Useful options:

```bash
# Show all available figure-generation jobs
python run_all_figures.py --list

# Run only selected figures
python run_all_figures.py --only Fig3 Fig4

# Skip selected figures
python run_all_figures.py --skip FigS8
```

Individual plotting scripts can also be run separately.

## Repository structure

```text
LFP_choice_probability_Zenodo_release_v1/
├── Source_Data/
│   ├── Fig1G_behavioral_sensitivity_values.csv
│   ├── Fig1G_behavioral_sensitivity_summary.csv
│   ├── Fig1G_behavioral_sensitivity_tests.csv
│   ├── Fig3_main_timecourse_values.csv
│   ├── Fig3_main_epoch_summary_values.csv
│   ├── FigS1S3_monkeywise_trace_source_values.csv
│   ├── FigS1S3_epoch_summary_values.csv
│   ├── Fig4BC_loading_energy_values.csv
│   ├── Fig4BC_loading_energy_summary.csv
│   ├── Fig4BC_loading_energy_tests.csv
│   ├── Fig4DG_reward_history_values.csv
│   ├── Fig4DG_reward_history_summary.csv
│   ├── Fig4DG_reward_history_tests.csv
│   ├── FigS5AB_decoder_accuracy_values.csv
│   ├── FigS5AB_decoder_accuracy_summary.csv
│   ├── FigS5AB_decoder_accuracy_tests.csv
│   ├── FigS8_saline_control_values.csv
│   ├── FigS8_saline_control_values_long.csv
│   ├── FigS8_saline_control_summary.csv
│   ├── FigS8_saline_control_tests.csv
│   └── README.md
├── Code/
│   ├── figure_generation/
│   │   ├── plotting_helpers.py
│   │   ├── plot_fig1G_behavioral_sensitivity.py
│   │   ├── plot_fig3_cp_timecourses.py
│   │   ├── plot_fig4_frequency_specific_decomposition.py
│   │   ├── plot_figS1S3_monkeywise_cp.py
│   │   ├── plot_figS5AB_decoder_accuracy.py
│   │   ├── plot_figS8_saline_control.py
│   │   └── run_all_figures.py
│   └── analysis_pipeline/
│       ├── CP_computation/
│       │   ├── compute_auc.m
│       │   ├── sp_psth_LFP.m
│       │   ├── sp_psth_LFP_reward.m
│       │   ├── sp_cpz_LFP.m
│       │   ├── total_cp_LFP.m
│       │   └── README.md
│       └── FigS4_simulation/
│           ├── sim_neurodsp.py
│           ├── choice1.csv
│           ├── choice2.csv
│           ├── choice1_scaled.csv
│           ├── choice2_scaled.csv
│           ├── choice1_zscored.csv
│           ├── choice2_zscored.csv
│           ├── choice1_zscore_conven.csv
│           ├── choice2_zscore_conven.csv
│           ├── plot_cp_heatmap.R
│           ├── plot_cp_bands_epochs.R
│           └── README.md
├── Output/
│   └── generated_figures/
├── requirements.txt
├── LICENSE
└── README.md
```

## Released animal labels

The released source data use manuscript-consistent animal labels:

| Released label | Cortical area |
|---|---|
| `Monkey_Y` | MT |
| `Monkey_C` | MT |
| `Monkey_L` | V4 |
| `Monkey_A` | V4 |

## Source-data files

The `Source_Data/` folder contains individual numerical values and summary tables used to reproduce plotted means and errors.

| File type | Meaning |
|---|---|
| `*_values.csv` | Underlying numerical values used for plotting and summary calculation |
| `*_summary.csv` | Derived means and standard errors |
| `*_tests.csv` | Statistical-test outputs associated with the relevant panels |

| Manuscript panel | Source-data file(s) | What each row represents |
|---|---|---|
| Fig. 1G | `Fig1G_behavioral_sensitivity_values.csv` | One session and inactivation condition |
| Fig. 3 area time courses | `Fig3_main_timecourse_values.csv` | Time-resolved CP traces and SEMs for MT and V4; one row per frequency band, area, time point, and inactivation condition |
| Fig. 3 aggregation column and reported epoch summaries | `Fig3_main_epoch_summary_values.csv` | Mean ± SEM CP values for baseline, stimulus-response, and delay epochs; rows with `aggregation_level = All` reproduce the Fig. 3 aggregation panels |
| Fig. S1-S3 | `FigS1S3_monkeywise_trace_source_values.csv` | Time-resolved monkey-wise mean ± SEM CP traces |
| Fig. 4B-C | `Fig4BC_loading_energy_values.csv` | One session, condition, axis, and frequency band |
| Fig. 4D-G | `Fig4DG_reward_history_values.csv` | One time-frequency CP estimate within the selected alpha-beta baseline window |
| Fig. S5A-B | `FigS5AB_decoder_accuracy_values.csv` | One session and inactivation condition |
| Fig. S8 | `FigS8_saline_control_values.csv` | One matched stimulus/image pair before and after saline |

## Analysis-pipeline code

The folder `Code/analysis_pipeline/` documents upstream analyses (a.k.a the heart of this project). These scripts are included for methodological transparency and future collaboration.

### CP computation

```text
Code/analysis_pipeline/CP_computation/
```

This folder contains MATLAB scripts documenting the upstream LFP-based choice-probability workflow.

| File | Purpose |
|---|---|
| `sp_psth_LFP.m` | Computes LFP spectrogram/power estimates used for CP analyses |
| `sp_psth_LFP_reward.m` | Computes LFP spectrogram/power estimates for reward-history analyses |
| `sp_cpz_LFP.m` | Computes LFP-based choice probability after normalization and trial balancing |
| `total_cp_LFP.m` | Example wrapper for computing CP from LFP inputs |
| `roc_curve_LFP.m` | Computes ROC curves |

These scripts may require raw electrophysiological files that are not included in this source-data release. They also require MATLAB and, for spectral estimation, the Chronux toolbox.

### Figure S4 simulation

```text
Code/analysis_pipeline/FigS4_simulation/
```

This folder contains the simulation and plotting files used to document the normalization-control logic for LFP power.

| File | Purpose |
|---|---|
| `sim_neurodsp.py` | Simulates synthetic LFP-like signals using NeuroDSP |
| `choice1.csv`, `choice2.csv` | Simulated raw signal examples |
| `choice1_scaled.csv`, `choice2_scaled.csv` | Robust-scaled simulated signal outputs |
| `choice1_zscored.csv`, `choice2_zscored.csv` | Z-scored simulated signal outputs |
| `choice1_zscore_conven.csv`, `choice2_zscore_conven.csv` | Conventional z-scored simulated signal outputs |
| `plot_cp_heatmap.R` | Plots simulated CP heatmaps |
| `plot_cp_bands_epochs.R` | Plots simulated CP summaries across bands/epochs |

### Upstream analysis-pipeline scripts

The upstream scripts may require additional software:

| Component | Requirement |
|---|---|
| CP computation | MATLAB |
| LFP spectral estimation | Chronux toolbox |
| Figure S4 simulation | Python with `neurodsp`|
| Figure S4 plotting | R |

## License

Code is released under the MIT License. Source data are provided for reuse with citation of the manuscript and Zenodo archive.
