#!/usr/bin/env python3
"""
Verify Figure 3 and Supplementary Figure S1-S3 mean ± SEM values.

Expected location when placed in repository:
    LFP_choice_probability_Zenodo_release_v1/Code/figure_generation/verify_fig3_S1S3_mean_sem.py

Inputs:
    ../../Source_Data/Fig3_main_epoch_summary_values.csv
    ../../Source_Data/FigS1S3_epoch_summary_values.csv
    ../../Source_Data/Fig3_S1S3_mean_sem_alignment_check.csv   [optional]

Output:
    ../../Output/generated_statistics/Fig3_S1S3_mean_sem_verification.csv

This script checks the source-data mean ± SEM values against the stored
alignment-check table, when the alignment-check table is present.
"""

from pathlib import Path
import pandas as pd

ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "Source_Data"
OUTPUT_DIR = ROOT / "Output" / "generated_statistics"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

FIG3_SUMMARY = SOURCE_DIR / "Fig3_main_epoch_summary_values.csv"
FIGS_SUMMARY = SOURCE_DIR / "FigS1S3_epoch_summary_values.csv"
ALIGNMENT_CHECK = SOURCE_DIR / "Fig3_S1S3_mean_sem_alignment_check.csv"
OUT_FILE = OUTPUT_DIR / "Fig3_S1S3_mean_sem_verification.csv"


def main() -> None:
    for required in [FIG3_SUMMARY, FIGS_SUMMARY]:
        if not required.exists():
            raise FileNotFoundError(f"Missing required source-data file: {required}")

    fig3 = pd.read_csv(FIG3_SUMMARY)
    figs = pd.read_csv(FIGS_SUMMARY)

    rows = []
    for _, r in fig3.iterrows():
        rows.append({
            "source_set": "Fig3_main_epoch_summary",
            "figure_panel": r["figure_panel"],
            "frequency_band": r["frequency_band"],
            "aggregation_level": r["aggregation_level"],
            "monkey_id": "",
            "area": r["area"],
            "epoch": r["epoch"],
            "condition": r["condition"],
            "mean_cp": r["mean_cp"],
            "sem_cp": r["sem_cp"],
            "rounded_mean_3dp": round(float(r["mean_cp"]), 3),
            "rounded_sem_3dp": round(float(r["sem_cp"]), 3),
        })

    for _, r in figs.iterrows():
        rows.append({
            "source_set": "FigS1S3_epoch_summary",
            "figure_panel": r["figure_panel"],
            "frequency_band": r["frequency_band"],
            "aggregation_level": "monkey",
            "monkey_id": r["monkey_id"],
            "area": r["area"],
            "epoch": r["epoch"],
            "condition": r["condition"],
            "mean_cp": r["mean_cp"],
            "sem_cp": r["sem_cp"],
            "rounded_mean_3dp": round(float(r["mean_cp"]), 3),
            "rounded_sem_3dp": round(float(r["sem_cp"]), 3),
        })

    out = pd.DataFrame(rows)

    if ALIGNMENT_CHECK.exists():
        check = pd.read_csv(ALIGNMENT_CHECK)
        if "match_reported_after_rounding" in check.columns:
            n_total = len(check)
            n_match = int(check["match_reported_after_rounding"].sum())
            print(f"Stored manuscript alignment check: {n_match}/{n_total} values match after rounding.")
            if n_match != n_total:
                print("WARNING: At least one reported value does not match the stored source-data check.")
                print(check.loc[~check["match_reported_after_rounding"].astype(bool)].to_string(index=False))

    out.to_csv(OUT_FILE, index=False)
    print(f"Saved: {OUT_FILE}")
    print(out.to_string(index=False))


if __name__ == "__main__":
    main()
