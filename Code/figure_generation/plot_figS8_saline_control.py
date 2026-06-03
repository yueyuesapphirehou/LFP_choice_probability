#!/usr/bin/env python3
"""
Generate Fig. S8 from source data.

Panel: saline-control firing rates before and after saline injection.
Input:  Source_Data/FigS8_saline_control_values.csv
Output: Output/generated_figures/FigS8_saline_control.{pdf,png}
"""

import numpy as np
import matplotlib.pyplot as plt
from plotting_helpers import read_source_csv, sem, panel_label, save_figure, BLUE

def main():
    values = read_source_csv("FigS8_saline_control_values.csv").copy()
    pre = values["pre_firing_rate_hz"].to_numpy(float)
    post = values["post_firing_rate_hz"].to_numpy(float)

    fig, ax = plt.subplots(figsize=(3.3, 3.2))
    ax.bar(1, np.mean(pre), width=0.55, color="black", alpha=0.35, edgecolor="none")
    ax.bar(2, np.mean(post), width=0.55, color=BLUE, alpha=0.35, edgecolor="none")
    ax.errorbar([1, 2], [np.mean(pre), np.mean(post)], yerr=[sem(pre), sem(post)],
                color="black", linestyle="none", linewidth=1.2, capsize=5, zorder=5)

    rng = np.random.default_rng(6)
    x_pre = 1 + rng.normal(0, 0.04, size=len(pre))
    x_post = 2 + rng.normal(0, 0.04, size=len(post))
    for i in range(len(values)):
        ax.plot([x_pre[i], x_post[i]], [pre[i], post[i]],
                color="#B0B0B0", alpha=0.45, linewidth=0.8, zorder=1)

    ax.scatter(x_pre, pre, s=26, color="black", alpha=0.65, linewidth=0, zorder=6)
    ax.scatter(x_post, post, s=26, color=BLUE, alpha=0.65, linewidth=0, zorder=6)

    # Median markers, as described in the manuscript legend.
    ax.scatter([1], [np.median(pre)], s=54, color="black", edgecolor="black", zorder=7)
    ax.scatter([2], [np.median(post)], s=54, color=BLUE, edgecolor=BLUE, zorder=7)

    ax.set_xticks([1, 2])
    ax.set_xticklabels(["Pre-saline", "Post-saline"])
    ax.set_ylabel("Firing rate (sp/s)")
    ax.set_xlim(0.5, 2.5)
    ax.set_ylim(bottom=0)
    panel_label(ax, "S8", x=-0.18, y=1.06)

    fig.tight_layout()
    save_figure(fig, "FigS8_saline_control")

if __name__ == "__main__":
    main()
