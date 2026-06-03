#!/usr/bin/env python3
"""
Shared plotting helpers for the LFP choice probability project.

All figure-generation scripts read only from ../Source_Data and write to
../Output/generated_figures by default. No local user paths are required.
"""

from pathlib import Path
import numpy as np
import pandas as pd
import matplotlib.pyplot as plt

# Use Type 42 fonts in PDF so text remains editable in vector graphics editors.
plt.rcParams["pdf.fonttype"] = 42
plt.rcParams["ps.fonttype"] = 42
plt.rcParams["font.family"] = "DejaVu Sans"  # bundled with Matplotlib; editable Type 42 PDF text
plt.rcParams["axes.spines.top"] = False
plt.rcParams["axes.spines.right"] = False

BLACK = "black"
BLUE = "#0072B2"
LIGHT_BLUE = "#DCECFB"
GRAY = "#A6A6A6"
DARK_GRAY = "#666666"
LIGHT_GRAY = "#CFCFCF"


def repo_root() -> Path:
    return Path(__file__).resolve().parents[2]


def source_data_dir() -> Path:
    return repo_root() / "Source_Data"


def output_dir() -> Path:
    out = repo_root() / "Output" / "generated_figures"
    out.mkdir(parents=True, exist_ok=True)
    return out


def read_source_csv(filename: str) -> pd.DataFrame:
    return pd.read_csv(source_data_dir() / filename)


def sem(values):
    values = np.asarray(values, dtype=float)
    values = values[np.isfinite(values)]
    if len(values) <= 1:
        return np.nan
    return np.std(values, ddof=1) / np.sqrt(len(values))


def panel_label(ax, label: str, x=-0.18, y=1.08):
    ax.text(x, y, label, transform=ax.transAxes, fontsize=13,
            fontweight="bold", va="top", ha="left")


def save_figure(fig, basename: str):
    out = output_dir()
    pdf = out / f"{basename}.pdf"
    png = out / f"{basename}.png"
    fig.savefig(pdf, bbox_inches="tight")
    fig.savefig(png, dpi=400, bbox_inches="tight")
    print(f"Saved {pdf}")
    print(f"Saved {png}")


def paired_bar(ax, x_positions, pre_values, post_values, colors=("white", "white"),
               pre_marker="o", post_marker="D", jitter=0.035,
               edge_color="black", connect_color="#B0B0B0", seed=1,
               bar_width=0.32, error_color="black"):
    """Draw paired pre/post bars with paired lines and jittered points."""
    rng = np.random.default_rng(seed)

    pre_values = np.asarray(pre_values, dtype=float)
    post_values = np.asarray(post_values, dtype=float)

    means = [np.nanmean(pre_values), np.nanmean(post_values)]
    errors = [sem(pre_values), sem(post_values)]

    # Bars
    ax.bar(x_positions[0], means[0], width=bar_width, color=colors[0],
           edgecolor=edge_color, linewidth=1.3)
    ax.bar(x_positions[1], means[1], width=bar_width, color=colors[1],
           edgecolor=edge_color, linewidth=1.3, linestyle="--")
    ax.errorbar(x_positions, means, yerr=errors, color=error_color,
                linestyle="none", linewidth=1.2, capsize=4, zorder=5)

    xp = x_positions[0] + rng.uniform(-jitter, jitter, size=len(pre_values))
    xq = x_positions[1] + rng.uniform(-jitter, jitter, size=len(post_values))
    ax.scatter(xp, pre_values, s=28, marker=pre_marker, color="black",
               edgecolor="black", linewidth=0.5, zorder=6)
    ax.scatter(xq, post_values, s=28, marker=post_marker, facecolor="black",
               edgecolor="black", linewidth=0.5, zorder=6)
