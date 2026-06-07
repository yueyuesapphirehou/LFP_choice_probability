#!/usr/bin/env python3
"""
Figure 3: frequency- and epoch-specific LFP choice probability.

This script regenerates Fig. 3 from two canonical source-data files in
Source_Data/:

    Fig3_main_timecourse_values.csv
    Fig3_main_epoch_summary_values.csv

The timecourse file contains the MT and V4 traces used for the left and middle
columns. The epoch-summary file contains the epoch-level aggregation values used
for the right column and the manuscript-reported epoch summaries.
"""

from __future__ import annotations

from pathlib import Path
from typing import Tuple

import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# ---------------------------------------------------------------------
# Paths
# ---------------------------------------------------------------------
SCRIPT_DIR = Path(__file__).resolve().parent
REPO_ROOT = SCRIPT_DIR.parents[1]
SOURCE_DIR = REPO_ROOT / "Source_Data"
OUT_DIR = REPO_ROOT / "Output" / "generated_figures"
OUT_DIR.mkdir(parents=True, exist_ok=True)

TIMECOURSE_FILE = SOURCE_DIR / "Fig3_main_timecourse_values.csv"
EPOCH_SUMMARY_FILE = SOURCE_DIR / "Fig3_main_epoch_summary_values.csv"

# ---------------------------------------------------------------------
# Figure settings
# ---------------------------------------------------------------------
PRE_COLOR = "black"
POST_COLOR = "#0072B2"
STIM_SHADE = "#F7C6D0"
BASELINE_LINE = "#808080"

BANDS = [
    {
        "band_key": "high_gamma",
        "panel": "A",
        "label": "High gamma\n(70–150 Hz)",
        "sig": "***",
        "area_ylim": {"MT": (0.48, 0.52), "V4": (0.47, 0.57)},
        "agg_ylim": (0.488, 0.527),
    },
    {
        "band_key": "low_gamma",
        "panel": "B",
        "label": "Low gamma\n(30–70 Hz)",
        "sig": "n.s.",
        "area_ylim": {"MT": (0.47, 0.545), "V4": (0.44, 0.57)},
        "agg_ylim": (0.487, 0.535),
    },
    {
        "band_key": "alpha_beta",
        "panel": "C",
        "label": "Alpha–beta\n(5–30 Hz)",
        "sig": "n.s.",
        "area_ylim": {"MT": (0.47, 0.54), "V4": (0.43, 0.59)},
        "agg_ylim": (0.472, 0.526),
    },
]

AREA_TITLES = {"MT": "Area MT", "V4": "Area V4"}
EPOCH_ORDER = ["baseline", "stimulus", "delay"]
EPOCH_LABELS = ["baseline", "stimulus\nresponse", "delay"]

# ---------------------------------------------------------------------
# Helpers
# ---------------------------------------------------------------------
def require_file(path: Path) -> Path:
    if not path.exists():
        required = [
            "Fig3_main_timecourse_values.csv",
            "Fig3_main_epoch_summary_values.csv",
        ]
        msg = [
            f"Required source-data file not found: {path}",
            "",
            "This Figure 3 script uses the canonical manuscript-style source-data files.",
            f"Please place the following files in: {SOURCE_DIR}",
        ]
        msg += [f"  - {name}" for name in required]
        raise FileNotFoundError("\n".join(msg))
    return path


def load_timecourse_source() -> pd.DataFrame:
    path = require_file(TIMECOURSE_FILE)
    df = pd.read_csv(path)
    required_cols = {
        "frequency_band", "area", "time_ms", "condition", "mean_cp", "sem_cp"
    }
    missing = required_cols.difference(df.columns)
    if missing:
        raise ValueError(f"{path.name} is missing columns: {sorted(missing)}")
    return df.copy()


def load_epoch_summary_source() -> pd.DataFrame:
    path = require_file(EPOCH_SUMMARY_FILE)
    df = pd.read_csv(path)
    required_cols = {
        "frequency_band", "aggregation_level", "epoch", "condition", "mean_cp", "sem_cp"
    }
    missing = required_cols.difference(df.columns)
    if missing:
        raise ValueError(f"{path.name} is missing columns: {sorted(missing)}")
    return df.copy()


def load_area(trace_df: pd.DataFrame, band_key: str, area: str) -> pd.DataFrame:
    sub = trace_df[
        (trace_df["frequency_band"] == band_key) &
        (trace_df["area"] == area)
    ].copy()
    if sub.empty:
        raise ValueError(f"No timecourse rows found for frequency_band={band_key}, area={area}")

    wide = sub.pivot_table(
        index="time_ms",
        columns="condition",
        values=["mean_cp", "sem_cp"],
        aggfunc="first",
    )
    required_pairs = [("mean_cp", "pre"), ("sem_cp", "pre"), ("mean_cp", "post"), ("sem_cp", "post")]
    for pair in required_pairs:
        if pair not in wide.columns:
            raise ValueError(f"Missing condition column {pair} for frequency_band={band_key}, area={area}")

    out = pd.DataFrame({
        "time_ms": wide.index.astype(float),
        "CP_pre": wide[("mean_cp", "pre")].to_numpy(dtype=float),
        "CP_pre_sem": wide[("sem_cp", "pre")].to_numpy(dtype=float),
        "CP_post": wide[("mean_cp", "post")].to_numpy(dtype=float),
        "CP_post_sem": wide[("sem_cp", "post")].to_numpy(dtype=float),
    }).sort_values("time_ms").reset_index(drop=True)

    expected_n = 31
    if len(out) != expected_n:
        raise ValueError(
            f"Expected {expected_n} time points for frequency_band={band_key}, area={area}; found {len(out)}"
        )
    return out


def load_aggregation(summary_df: pd.DataFrame, band_key: str) -> pd.DataFrame:
    sub = summary_df[
        (summary_df["frequency_band"] == band_key) &
        (summary_df["aggregation_level"] == "All")
    ].copy()
    if sub.empty:
        raise ValueError(f"No aggregation rows found for frequency_band={band_key}")

    wide = sub.pivot_table(
        index="epoch",
        columns="condition",
        values=["mean_cp", "sem_cp"],
        aggfunc="first",
    )
    rows = []
    for epoch in EPOCH_ORDER:
        if epoch not in wide.index:
            raise ValueError(f"Missing epoch={epoch} for frequency_band={band_key}")
        required_pairs = [("mean_cp", "pre"), ("sem_cp", "pre"), ("mean_cp", "post"), ("sem_cp", "post")]
        for pair in required_pairs:
            if pair not in wide.columns:
                raise ValueError(f"Missing condition column {pair} for frequency_band={band_key}, epoch={epoch}")
        rows.append({
            "epoch": epoch,
            "CP_pre": float(wide.loc[epoch, ("mean_cp", "pre")]),
            "CP_pre_sem": float(wide.loc[epoch, ("sem_cp", "pre")]),
            "CP_post": float(wide.loc[epoch, ("mean_cp", "post")]),
            "CP_post_sem": float(wide.loc[epoch, ("sem_cp", "post")]),
        })
    return pd.DataFrame(rows)


def add_timecourse_panel(ax, df: pd.DataFrame, ylim: Tuple[float, float], show_xlabel: bool) -> None:
    t = df["time_ms"].to_numpy(dtype=float)
    pre = df["CP_pre"].to_numpy(dtype=float)
    pre_sem = df["CP_pre_sem"].to_numpy(dtype=float)
    post = df["CP_post"].to_numpy(dtype=float)
    post_sem = df["CP_post_sem"].to_numpy(dtype=float)

    ax.axvspan(50, 250, color=STIM_SHADE, alpha=0.25, zorder=0)
    ax.axhline(0.5, color=BASELINE_LINE, linestyle="--", linewidth=1.0, zorder=1)
    ax.axvline(0, color=BASELINE_LINE, linestyle="--", linewidth=1.0, zorder=1)

    ax.fill_between(t, pre - pre_sem, pre + pre_sem, color=PRE_COLOR, alpha=0.18, linewidth=0, zorder=2)
    ax.plot(t, pre, color=PRE_COLOR, linewidth=2.2, zorder=3)
    ax.fill_between(t, post - post_sem, post + post_sem, color=POST_COLOR, alpha=0.18, linewidth=0, zorder=2)
    ax.plot(t, post, color=POST_COLOR, linewidth=2.2, zorder=3)

    ax.set_xlim(-200, 400)
    ax.set_ylim(*ylim)
    ax.set_xticks([-200, -100, 0, 100, 200, 300, 400])
    if show_xlabel:
        ax.set_xlabel("Time from stimulus onset (ms)", fontsize=9)
    else:
        ax.set_xticklabels([])

    ax.tick_params(axis="both", labelsize=8, width=1, length=3)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    for side in ["left", "bottom"]:
        ax.spines[side].set_linewidth(1.0)


def add_aggregation_panel(ax, df: pd.DataFrame, ylim: Tuple[float, float], sig_label: str) -> None:
    x = np.arange(len(EPOCH_ORDER), dtype=float)
    pre = df["CP_pre"].to_numpy(dtype=float)
    pre_sem = df["CP_pre_sem"].to_numpy(dtype=float)
    post = df["CP_post"].to_numpy(dtype=float)
    post_sem = df["CP_post_sem"].to_numpy(dtype=float)

    ax.axhline(0.5, color=BASELINE_LINE, linestyle="--", linewidth=1.0, zorder=1)
    ax.errorbar(x, pre, yerr=pre_sem, color=PRE_COLOR, marker="o", markersize=3.5,
                linewidth=2.0, capsize=2.5, zorder=3)
    ax.errorbar(x, post, yerr=post_sem, color=POST_COLOR, marker="o", markersize=3.5,
                linewidth=2.0, capsize=2.5, zorder=3)

    ax.set_xlim(-0.15, 2.15)
    ax.set_ylim(*ylim)
    ax.set_xticks(x)
    ax.set_xticklabels(EPOCH_LABELS, rotation=20, ha="right", fontsize=8)
    ax.tick_params(axis="y", labelsize=8, width=1, length=3)
    ax.tick_params(axis="x", width=1, length=3)
    ax.spines["top"].set_visible(False)
    ax.spines["right"].set_visible(False)
    for side in ["left", "bottom"]:
        ax.spines[side].set_linewidth(1.0)

    # Significance marker over stimulus-response epoch.
    y_top = ylim[1] - 0.08 * (ylim[1] - ylim[0])
    y_bar = ylim[1] - 0.13 * (ylim[1] - ylim[0])
    ax.plot([0.82, 1.18], [y_bar, y_bar], color="black", linewidth=1.0, clip_on=False)
    ax.text(1.0, y_top, sig_label, ha="center", va="bottom", fontsize=10, fontweight="bold")


# ---------------------------------------------------------------------
# Main
# ---------------------------------------------------------------------
def main() -> None:
    plt.rcParams.update({
        "font.family": "Arial",
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.linewidth": 1.0,
    })

    trace_df = load_timecourse_source()
    summary_df = load_epoch_summary_source()

    fig = plt.figure(figsize=(8.3, 7.2))
    gs = fig.add_gridspec(
        nrows=3,
        ncols=3,
        left=0.14,
        right=0.98,
        top=0.94,
        bottom=0.12,
        wspace=0.34,
        hspace=0.34,
        width_ratios=[1.0, 1.0, 0.72],
    )

    axes = [[fig.add_subplot(gs[r, c]) for c in range(3)] for r in range(3)]

    for r, band in enumerate(BANDS):
        band_key = band["band_key"]
        show_xlabel = r == 2

        # Left and middle columns: MT and V4 time courses.
        for c, area in enumerate(["MT", "V4"]):
            ax = axes[r][c]
            df_area = load_area(trace_df, band_key, area)
            add_timecourse_panel(ax, df_area, band["area_ylim"][area], show_xlabel)
            if r == 0:
                ax.set_title(AREA_TITLES[area], fontsize=11, fontweight="bold", pad=5)
            if c == 0:
                ax.set_ylabel("Choice probability", fontsize=9)
            else:
                ax.set_ylabel("")
            # Stimulus-window significance marker in area panels.
            y = band["area_ylim"][area][1] - 0.08 * (band["area_ylim"][area][1] - band["area_ylim"][area][0])
            ax.text(150, y, band["sig"], ha="center", va="bottom", fontsize=10, fontweight="bold")

        # Right column: epoch aggregation.
        ax_agg = axes[r][2]
        df_agg = load_aggregation(summary_df, band_key)
        add_aggregation_panel(ax_agg, df_agg, band["agg_ylim"], band["sig"])
        if r == 0:
            ax_agg.set_title("Aggregation", fontsize=11, fontweight="bold", pad=5)
        ax_agg.set_ylabel("Choice probability", fontsize=9)

        # Row labels and panel letters.
        row_ax = axes[r][0]
        row_ax.text(
            -0.47, 0.50, band["label"], transform=row_ax.transAxes,
            ha="right", va="center", fontsize=11, fontweight="bold", linespacing=0.9,
        )
        row_ax.text(
            -0.62, 1.08, band["panel"], transform=row_ax.transAxes,
            ha="left", va="top", fontsize=13, fontweight="bold",
        )

    # Legend at bottom center.
    from matplotlib.lines import Line2D
    legend_handles = [
        Line2D([0], [0], color=PRE_COLOR, linewidth=4, label="Pre-inactivation"),
        Line2D([0], [0], color=POST_COLOR, linewidth=4, label="Post-inactivation"),
    ]
    fig.legend(
        handles=legend_handles,
        loc="lower center",
        bbox_to_anchor=(0.54, 0.035),
        ncol=2,
        frameon=False,
        fontsize=10,
        handlelength=2.3,
        columnspacing=3.0,
    )

    out_pdf = OUT_DIR / "Fig3_CP_timecourses.pdf"
    out_png = OUT_DIR / "Fig3_CP_timecourses.png"
    fig.savefig(out_pdf, bbox_inches="tight")
    fig.savefig(out_png, dpi=300, bbox_inches="tight")
    plt.close(fig)
    print(f"Saved: {out_pdf}")
    print(f"Saved: {out_png}")


if __name__ == "__main__":
    main()
