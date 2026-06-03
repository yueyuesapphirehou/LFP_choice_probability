#!/usr/bin/env python3
"""
Generate Fig. 1G from source data.

Panel: session-wise behavioral sensitivity before and after inactivation.
Input:  Source_Data/Fig1G_behavioral_sensitivity_values.csv
Output: Output/generated_figures/Fig1G_behavioral_sensitivity.{pdf,png}
"""

import numpy as np
import matplotlib.pyplot as plt
from plotting_helpers import read_source_csv, sem, panel_label, save_figure

MONKEY_ORDER = ["Monkey_C", "Monkey_Y", "Monkey_A", "Monkey_L"]
SHORT_LABELS = ["C", "Y", "A", "L"]

def main():
    values = read_source_csv("Fig1G_behavioral_sensitivity_values.csv")

    fig, ax = plt.subplots(figsize=(5.2, 3.2))
    dx = 0.18
    bar_width = 0.32
    rng = np.random.default_rng(3)

    for i, monkey in enumerate(MONKEY_ORDER, start=1):
        sub = values[values["monkey_id"] == monkey].copy()
        pre = sub[sub["condition"] == "pre"].sort_values("session_id")
        post = sub[sub["condition"] == "post"].sort_values("session_id")

        y_pre = pre["sensitivity"].to_numpy(float)
        y_post = post["sensitivity"].to_numpy(float)

        x_pre = i - dx
        x_post = i + dx

        ax.bar(x_pre, np.mean(y_pre), width=bar_width, color="white",
               edgecolor="black", linewidth=1.3)
        ax.bar(x_post, np.mean(y_post), width=bar_width, color="white",
               edgecolor="black", linewidth=1.3, linestyle="--")
        ax.errorbar([x_pre, x_post],
                    [np.mean(y_pre), np.mean(y_post)],
                    yerr=[sem(y_pre), sem(y_post)],
                    color="black", linestyle="none", linewidth=1.2, capsize=4)

        # Pair sessions by session_id.
        merged = pre[["session_id", "sensitivity"]].merge(
            post[["session_id", "sensitivity"]],
            on="session_id", suffixes=("_pre", "_post")
        )
        for _, row in merged.iterrows():
            ax.plot([x_pre, x_post], [row["sensitivity_pre"], row["sensitivity_post"]],
                    color="#B0B0B0", linewidth=0.8, zorder=1)

        ax.scatter(x_pre + rng.uniform(-0.04, 0.04, size=len(y_pre)), y_pre,
                   s=35, color="black", edgecolor="black", zorder=4)
        ax.scatter(x_post + rng.uniform(-0.04, 0.04, size=len(y_post)), y_post,
                   s=35, marker="D", color="black", edgecolor="black", zorder=4)

        y_top = max(np.max(y_pre), np.max(y_post)) * 1.08
        ax.text(x_pre, y_top, f"n={len(y_pre)}", ha="center", va="bottom", fontsize=8)
        ax.text(x_post, y_top, f"n={len(y_post)}", ha="center", va="bottom", fontsize=8)

    ax.set_xticks(np.arange(1, len(MONKEY_ORDER) + 1))
    ax.set_xticklabels(SHORT_LABELS)
    ax.set_xlabel("Monkey")
    ax.set_ylabel("Behavioral sensitivity (1/threshold)")
    ax.set_xlim(0.4, len(MONKEY_ORDER) + 0.6)
    ax.set_ylim(bottom=0)
    panel_label(ax, "G", x=-0.14, y=1.06)

    fig.tight_layout()
    save_figure(fig, "Fig1G_behavioral_sensitivity")


if __name__ == "__main__":
    main()
