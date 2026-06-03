#!/usr/bin/env python3
"""
Figure 3: frequency- and epoch-specific LFP choice probability.

This script uses source-data CSV files deposited in Source_Data/ and writes the
figure to Output/generated_figures/.

Required source-data files in Source_Data/:
    highgamma_MT.csv
    highgamma_V4.csv
    highgamma_grand.csv
    lowgamma_MT.csv
    lowgamma_V4.csv
    lowgamma_grand.csv
    alphabeta_MT.csv
    alphabeta_V4.csv
    alphabeta_grand.csv

The area CSVs contain time-resolved mean CP and SEM traces for MT and V4.
The grand CSVs contain epoch-level aggregation values for baseline, stimulus,
and delay.
"""

from __future__ import annotations

from pathlib import Path
from typing import Dict, Tuple

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

# ---------------------------------------------------------------------
# Figure settings
# ---------------------------------------------------------------------
PRE_COLOR = "black"
POST_COLOR = "#0072B2"
STIM_SHADE = "#F7C6D0"
BASELINE_LINE = "#808080"

BANDS = [
    {
        "prefix": "highgamma",
        "panel": "A",
        "label": "High gamma\n(70–150 Hz)",
        "title": "High gamma (70–150 Hz)",
        "sig": "***",
        "area_ylim": {"MT": (0.48, 0.52), "V4": (0.47, 0.57)},
        "agg_ylim": (0.488, 0.527),
    },
    {
        "prefix": "lowgamma",
        "panel": "B",
        "label": "Low gamma\n(30–70 Hz)",
        "title": "Low gamma (30–70 Hz)",
        "sig": "n.s.",
        "area_ylim": {"MT": (0.47, 0.545), "V4": (0.44, 0.57)},
        "agg_ylim": (0.487, 0.535),
    },
    {
        "prefix": "alphabeta",
        "panel": "C",
        "label": "Alpha–beta\n(5–30 Hz)",
        "title": "Alpha–beta (5–30 Hz)",
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
            "highgamma_MT.csv", "highgamma_V4.csv", "highgamma_grand.csv",
            "lowgamma_MT.csv", "lowgamma_V4.csv", "lowgamma_grand.csv",
            "alphabeta_MT.csv", "alphabeta_V4.csv", "alphabeta_grand.csv",
        ]
        msg = [
            f"Required source-data file not found: {path}",
            "",
            "This Figure 3 script uses the manuscript-style source-data files.",
            f"Please place the following files in: {SOURCE_DIR}",
        ]
        msg += [f"  - {name}" for name in required]
        raise FileNotFoundError("\n".join(msg))
    return path


def load_area(prefix: str, area: str) -> pd.DataFrame:
    path = require_file(SOURCE_DIR / f"{prefix}_{area}.csv")
    df = pd.read_csv(path)
    required_cols = {"time_ms", "CP_pre", "CP_pre_sem", "CP_post", "CP_post_sem"}
    missing = required_cols.difference(df.columns)
    if missing:
        raise ValueError(f"{path.name} is missing columns: {sorted(missing)}")
    return df.sort_values("time_ms").reset_index(drop=True)


def load_grand(prefix: str) -> pd.DataFrame:
    path = require_file(SOURCE_DIR / f"{prefix}_grand.csv")
    df = pd.read_csv(path)
    required_cols = {"epoch", "CP_pre", "CP_pre_sem", "CP_post", "CP_post_sem"}
    missing = required_cols.difference(df.columns)
    if missing:
        raise ValueError(f"{path.name} is missing columns: {sorted(missing)}")
    df = df.copy()
    df["epoch"] = pd.Categorical(df["epoch"], categories=EPOCH_ORDER, ordered=True)
    return df.sort_values("epoch").reset_index(drop=True)


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


def add_aggregation_panel(ax, df: pd.DataFrame, ylim: Tuple[float, float], sig_label: str, show_xlabel: bool) -> None:
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
        prefix = band["prefix"]
        show_xlabel = r == 2

        # Left and middle columns: MT and V4 time courses.
        for c, area in enumerate(["MT", "V4"]):
            ax = axes[r][c]
            df_area = load_area(prefix, area)
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
        df_grand = load_grand(prefix)
        add_aggregation_panel(ax_agg, df_grand, band["agg_ylim"], band["sig"], show_xlabel)
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
