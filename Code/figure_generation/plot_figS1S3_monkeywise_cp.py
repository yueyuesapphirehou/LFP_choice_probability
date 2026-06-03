#!/usr/bin/env python3
"""
Generate Supplementary Figures S1-S3 monkey-wise CP time courses.

Expected location when placed in repository:
    LFP_choice_probability_Zenodo_release_v1/Code/figure_generation/plot_figS1S3_monkeywise_cp.py

Input:
    ../../Source_Data/FigS1S3_monkeywise_trace_source_values.csv

Output:
    ../../Output/generated_figures/FigS1_high_gamma_monkeywise_CP.pdf/png
    ../../Output/generated_figures/FigS2_low_gamma_monkeywise_CP.pdf/png
    ../../Output/generated_figures/FigS3_alpha_beta_monkeywise_CP.pdf/png

This script reproduces the plotted mean ± SEM traces only. It does not recompute
WSR/WRS p-values from expanded time-frequency observations.
"""

from pathlib import Path
import pandas as pd
import matplotlib.pyplot as plt

# -----------------------------
# Paths
# -----------------------------
ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "Source_Data"
OUTPUT_DIR = ROOT / "Output" / "generated_figures"
OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

SOURCE_FILE = SOURCE_DIR / "FigS1S3_monkeywise_trace_source_values.csv"

# -----------------------------
# Plot settings
# -----------------------------
PRE_COLOR = "black"
POST_COLOR = "#0072B2"
STIM_SHADE = "#f4cccc"

FIGURES = {
    "FigS1": {
        "band": "high_gamma",
        "title": "High-gamma (70–150 Hz) choice probability before and after cortical inactivation",
        "out_prefix": "FigS1_high_gamma_monkeywise_CP",
    },
    "FigS2": {
        "band": "low_gamma",
        "title": "Low-gamma (30–70 Hz) choice probability before and after cortical inactivation",
        "out_prefix": "FigS2_low_gamma_monkeywise_CP",
    },
    "FigS3": {
        "band": "alpha_beta",
        "title": "Alpha–beta (5–30 Hz) choice probability before and after cortical inactivation",
        "out_prefix": "FigS3_alpha_beta_monkeywise_CP",
    },
}

# Caption order: MT monkeys first, then V4 monkeys.
MONKEY_ORDER = ["Monkey_Y", "Monkey_C", "Monkey_L", "Monkey_A"]
PANEL_LETTER = {
    "Monkey_Y": "A",
    "Monkey_C": "B",
    "Monkey_L": "C",
    "Monkey_A": "D",
}


def _setup_matplotlib() -> None:
    plt.rcParams.update({
        "font.family": "Arial",
        "pdf.fonttype": 42,
        "ps.fonttype": 42,
        "axes.spines.top": False,
        "axes.spines.right": False,
        "axes.linewidth": 0.8,
        "xtick.major.width": 0.8,
        "ytick.major.width": 0.8,
        "font.size": 8,
    })


def _plot_trace(ax, sub: pd.DataFrame, condition: str, color: str, label: str) -> None:
    dat = sub[sub["condition"] == condition].sort_values("time_ms")
    x = dat["time_ms"].to_numpy(dtype=float)
    y = dat["mean_cp"].to_numpy(dtype=float)
    sem = dat["sem_cp"].to_numpy(dtype=float)
    ax.plot(x, y, color=color, linewidth=1.4, label=label)
    ax.fill_between(x, y - sem, y + sem, color=color, alpha=0.18, linewidth=0)


def _plot_one_figure(df: pd.DataFrame, fig_key: str, cfg: dict) -> None:
    band = cfg["band"]
    fig_df = df[df["frequency_band"] == band]
    if fig_df.empty:
        raise ValueError(f"No source-data rows found for band={band}")

    y_min = (fig_df["mean_cp"] - fig_df["sem_cp"]).min()
    y_max = (fig_df["mean_cp"] + fig_df["sem_cp"]).max()
    pad = max(0.005, (y_max - y_min) * 0.15)
    ylim = (y_min - pad, y_max + pad)

    fig, axes = plt.subplots(2, 2, figsize=(6.2, 4.8), sharex=False, sharey=True)
    axes = axes.ravel()

    for ax, monkey_id in zip(axes, MONKEY_ORDER):
        sub = fig_df[fig_df["monkey_id"] == monkey_id]
        if sub.empty:
            raise ValueError(f"No rows found for {fig_key}, {monkey_id}")
        area = sub["area"].iloc[0]

        ax.axvspan(50, 250, color=STIM_SHADE, alpha=0.35, zorder=0)
        ax.axhline(0.5, color="0.55", linestyle="--", linewidth=0.8, zorder=1)
        ax.axvline(0, color="0.70", linestyle="--", linewidth=0.6, zorder=1)

        _plot_trace(ax, sub, "pre", PRE_COLOR, "Pre-inactivation")
        _plot_trace(ax, sub, "post", POST_COLOR, "Post-inactivation")

        ax.set_xlim(0, 400)
        ax.set_ylim(*ylim)
        ax.set_xticks([0, 100, 200, 300, 400])
        ax.set_title(f"{PANEL_LETTER[monkey_id]}. {monkey_id.replace('_', ' ')} ({area})", fontsize=9)
        ax.set_xlabel("Time from stimulus onset (ms)", fontsize=8)
        ax.set_ylabel("Choice probability", fontsize=8)

    handles, labels = axes[0].get_legend_handles_labels()
    fig.legend(handles, labels, loc="upper right", bbox_to_anchor=(0.985, 0.995), frameon=False, fontsize=8)
    fig.suptitle(cfg["title"], fontsize=10, y=0.995)
    fig.tight_layout(rect=[0.03, 0.03, 0.965, 0.955])

    pdf_path = OUTPUT_DIR / f"{cfg['out_prefix']}.pdf"
    png_path = OUTPUT_DIR / f"{cfg['out_prefix']}.png"
    fig.savefig(pdf_path, bbox_inches="tight")
    fig.savefig(png_path, dpi=400, bbox_inches="tight")
    plt.close(fig)

    print(f"Saved: {pdf_path}")
    print(f"Saved: {png_path}")


def main() -> None:
    if not SOURCE_FILE.exists():
        raise FileNotFoundError(f"Missing source-data file: {SOURCE_FILE}")

    _setup_matplotlib()
    df = pd.read_csv(SOURCE_FILE)
    for fig_key, cfg in FIGURES.items():
        _plot_one_figure(df, fig_key, cfg)


if __name__ == "__main__":
    main()
