#!/usr/bin/env python3
"""
Generate Fig. S5A-B from source data.

Panel: high-gamma LFP stimulus decoder accuracy in MT and V4.
Input:  Source_Data/FigS5AB_decoder_accuracy_values.csv
Output: Output/generated_figures/FigS5AB_decoder_accuracy.{pdf,png}
"""

import numpy as np
import matplotlib.pyplot as plt
from plotting_helpers import read_source_csv, sem, panel_label, save_figure

def plot_area(ax, values, area, label):
    sub = values[values["area"] == area].copy()
    pre = sub[sub["condition"] == "pre"].sort_values(["monkey_id", "session_id"])
    post = sub[sub["condition"] == "post"].sort_values(["monkey_id", "session_id"])

    merged = pre.merge(post, on=["monkey_id", "session_id"], suffixes=("_pre", "_post"))
    y_pre = merged["accuracy_pre"].to_numpy(float)
    y_post = merged["accuracy_post"].to_numpy(float)

    x = [1, 2]
    ax.bar(x[0], np.mean(y_pre), width=0.55, color="#D0D0D0", edgecolor="none")
    ax.bar(x[1], np.mean(y_post), width=0.55, color="#E5E5E5", edgecolor="none")
    ax.errorbar(x, [np.mean(y_pre), np.mean(y_post)], yerr=[sem(y_pre), sem(y_post)],
                color="black", linestyle="none", linewidth=1.2, capsize=5, zorder=5)

    rng = np.random.default_rng(11)
    for i in range(len(merged)):
        xp = x[0] + rng.uniform(-0.035, 0.035)
        xq = x[1] + rng.uniform(-0.035, 0.035)
        ax.plot([xp, xq], [y_pre[i], y_post[i]], color="#8C8C8C", linewidth=0.9, zorder=1)
        ax.scatter(xp, y_pre[i], s=32, facecolor="black", edgecolor="black", zorder=6)
        ax.scatter(xq, y_post[i], s=32, facecolor="white", edgecolor="black", linewidth=0.9, zorder=6)

    ax.axhline(0.5, linestyle="--", color="#B0B0B0", linewidth=1.0)
    ax.set_xticks(x)
    ax.set_xticklabels(["Pre", "Post"])
    ax.set_ylim(0.35, 0.82)
    ax.set_ylabel("Decoder accuracy")
    ax.set_title(area)
    panel_label(ax, label, x=-0.16, y=1.06)

def main():
    values = read_source_csv("FigS5AB_decoder_accuracy_values.csv")
    fig, axes = plt.subplots(1, 2, figsize=(5.4, 3.2), sharey=True)
    plot_area(axes[0], values, "MT", "A")
    plot_area(axes[1], values, "V4", "B")
    axes[1].set_ylabel("")
    fig.tight_layout()
    save_figure(fig, "FigS5AB_decoder_accuracy")

if __name__ == "__main__":
    main()
