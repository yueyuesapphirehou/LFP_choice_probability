#!/usr/bin/env python3
"""
Generate the combined Figure 4 from source data.

Figure 4. Frequency-specific decomposition of decision-related LFP activity.

Panels:
B   Loading energy on the stimulus discrimination axis.
C   Loading energy on the leading null dimension.
D-G Alpha-beta reward-history CP for Monkey_Y, Monkey_C, Monkey_L, Monkey_A.

Inputs:
    Source_Data/Fig4BC_loading_energy_values.csv
    Source_Data/Fig4BC_loading_energy_tests.csv
    Source_Data/Fig4DG_reward_history_values.csv
    Source_Data/Fig4DG_reward_history_tests.csv

Output:
    Output/generated_figures/Fig4_frequency_specific_decomposition.{pdf,png}
"""

import numpy as np
import matplotlib.pyplot as plt
from matplotlib.gridspec import GridSpec
from matplotlib.patches import Ellipse
from plotting_helpers import read_source_csv, sem, panel_label, save_figure, BLUE, LIGHT_BLUE

BAND_ORDER = ["low_gamma", "high_gamma"]
BAND_LABELS = {"low_gamma": "Low gamma", "high_gamma": "High gamma"}
MONKEY_PANELS = [
    ("Fig4D", "Monkey_Y", "MT", "D"),
    ("Fig4E", "Monkey_C", "MT", "E"),
    ("Fig4F", "Monkey_L", "V4", "F"),
    ("Fig4G", "Monkey_A", "V4", "G"),
]

def significance_label(p):
    if p < 0.001:
        return "***"
    if p < 0.01:
        return "**"
    if p < 0.05:
        return "*"
    return "n.s."

def add_bracket(ax, x1, x2, y, text, h=0.018, fontsize=9):
    ax.plot([x1, x1, x2, x2], [y, y+h, y+h, y], color="black", linewidth=1.0, clip_on=False)
    ax.text((x1+x2)/2, y+h*1.25, text, ha="center", va="bottom", fontsize=fontsize)

def loading_panel(ax, values, tests, axis_name, title, panel_label_text):
    sub = values[values["axis"] == axis_name].copy()
    x_base = {"low_gamma": 1, "high_gamma": 2.3}
    dx = 0.16
    width = 0.28
    rng = np.random.default_rng(2)

    for band in BAND_ORDER:
        pre = sub[(sub["frequency_band"] == band) & (sub["condition"] == "pre")].sort_values(["monkey_id","session_id"])
        post = sub[(sub["frequency_band"] == band) & (sub["condition"] == "post")].sort_values(["monkey_id","session_id"])

        y_pre = pre["loading_energy"].to_numpy(float)
        y_post = post["loading_energy"].to_numpy(float)
        x_pre = x_base[band] - dx
        x_post = x_base[band] + dx

        ax.bar(x_pre, np.mean(y_pre), width=width, color="#BDBDBD", edgecolor="none")
        ax.bar(x_post, np.mean(y_post), width=width, color=LIGHT_BLUE, edgecolor="none")
        ax.errorbar([x_pre, x_post], [np.mean(y_pre), np.mean(y_post)],
                    yerr=[sem(y_pre), sem(y_post)], color="black",
                    linestyle="none", linewidth=1.1, capsize=3, zorder=5)

        merged = pre[["session_id","monkey_id","loading_energy"]].merge(
            post[["session_id","monkey_id","loading_energy"]],
            on=["session_id","monkey_id"], suffixes=("_pre","_post")
        )
        for _, row in merged.iterrows():
            ax.plot([x_pre, x_post], [row["loading_energy_pre"], row["loading_energy_post"]],
                    color="#A6A6A6", linewidth=0.7, zorder=1)

        ax.scatter(x_pre + rng.uniform(-0.035, 0.035, size=len(y_pre)), y_pre,
                   s=22, facecolor="black", edgecolor="black", linewidth=0.5, zorder=6)
        ax.scatter(x_post + rng.uniform(-0.035, 0.035, size=len(y_post)), y_post,
                   s=22, facecolor="white", edgecolor="black", linewidth=0.8, zorder=6)

    # Annotate pre and post LG-vs-HG comparisons with statistical testing.
    if axis_name == "stimulus_discrimination_axis":
        comp_text = "high_gamma > low_gamma"
        y_pre, y_post = 0.79, 0.865
    else:
        comp_text = "low_gamma > high_gamma"
        y_pre, y_post = 0.855, 0.735

    for condition, y in [("pre", y_pre), ("post", y_post)]:
        row = tests[(tests["axis"] == axis_name) &
                    (tests["condition"] == condition) &
                    (tests["comparison"] == comp_text)]
        if len(row):
            label = significance_label(float(row["p_value"].iloc[0]))
            add_bracket(ax, x_base["low_gamma"] + (-dx if condition == "pre" else dx),
                        x_base["high_gamma"] + (-dx if condition == "pre" else dx),
                        y, label, h=0.015)

    ax.set_xticks([x_base["low_gamma"], x_base["high_gamma"]])
    ax.set_xticklabels([BAND_LABELS[b] for b in BAND_ORDER], rotation=0)
    ax.set_ylabel("Band loading energy")
    ax.set_title(title, fontsize=10, fontweight="bold")
    ax.set_ylim(0, 0.91)
    panel_label(ax, panel_label_text, x=-0.18, y=1.10)

def reward_panel(ax, values, tests, monkey_id, area, panel_label_text):
    sub = values[values["monkey_id"] == monkey_id].copy()
    outcome_order = ["rewarded", "non_rewarded"]
    labels = ["Rewarded", "Non-rewarded"]
    x_base = {"rewarded": 1, "non_rewarded": 2.3}
    dx = 0.16
    width = 0.28
    rng = np.random.default_rng(5)

    for outcome in outcome_order:
        for cond, color, xoff in [("pre", "black", -dx), ("post", BLUE, dx)]:
            dat = sub[(sub["previous_trial_outcome"] == outcome) & (sub["condition"] == cond)]["cp"].to_numpy(float)
            x = x_base[outcome] + xoff
            ax.bar(x, np.mean(dat), width=width, color=color, alpha=0.70, edgecolor="none")
            ax.errorbar(x, np.mean(dat), yerr=sem(dat), color="black",
                        linestyle="none", linewidth=1.0, capsize=3, zorder=4)
            ax.scatter(x + rng.uniform(-0.045, 0.045, size=len(dat)), dat,
                       s=4, color=color, alpha=0.10, linewidth=0, zorder=5)

    # Rewarded vs non-rewarded comparison collapsed across pre/post, matching
    # the manuscript annotation and released tests.
    row = tests[(tests["monkey_id"] == monkey_id) & (tests["comparison_scope"] == "pre_and_post_collapsed")]
    if len(row):
        label = significance_label(float(row["p_value"].iloc[0]))
        add_bracket(ax, x_base["rewarded"]-dx, x_base["non_rewarded"]+dx, 0.579, label, h=0.0015)

    ax.axhline(0.5, linestyle="--", color="#8C8C8C", linewidth=0.9)
    ax.set_xticks([x_base["rewarded"], x_base["non_rewarded"]])
    ax.set_xticklabels(labels, fontsize=8)
    ax.set_ylim(0.40, 0.60)
    ax.set_title(f"{monkey_id.replace('Monkey_', 'Monkey ')}", fontsize=10)
    if panel_label_text == "D":
        ax.set_ylabel("Choice Probability (5–30 Hz)")
    else:
        ax.set_ylabel("")
    panel_label(ax, panel_label_text, x=-0.25, y=1.10)

def main():
    loading = read_source_csv("Fig4BC_loading_energy_values.csv")
    loading_tests = read_source_csv("Fig4BC_loading_energy_tests.csv")
    reward = read_source_csv("Fig4DG_reward_history_values.csv")
    reward_tests = read_source_csv("Fig4DG_reward_history_tests.csv")

    fig = plt.figure(figsize=(12.3, 6.2))
    gs = GridSpec(2, 4, figure=fig, height_ratios=[1.0, 1.05], width_ratios=[1,1,1,1],
                  hspace=0.55, wspace=0.45)

    axB = fig.add_subplot(gs[0, 0])
    loading_panel(axB, loading, loading_tests, "stimulus_discrimination_axis",
                  "Stimulus discrimination axis", "B")

    axC = fig.add_subplot(gs[0, 1])
    loading_panel(axC, loading, loading_tests, "leading_null_dimension",
                  "Leading null dimension", "C")

    # Third cell in the top row is used as an uncluttered legend for B-C.
    axLegend = fig.add_subplot(gs[0, 2])
    axLegend.axis("off")
    axLegend.scatter([0.08], [0.78], s=35, facecolor="black", edgecolor="black")
    axLegend.text(0.16, 0.78, "Pre-inactivation", va="center", fontsize=9)
    axLegend.scatter([0.08], [0.65], s=35, facecolor="white", edgecolor="black")
    axLegend.text(0.16, 0.65, "Post-inactivation", va="center", fontsize=9)
    axLegend.add_patch(plt.Rectangle((0.06, 0.45), 0.06, 0.05, color="#BDBDBD"))
    axLegend.text(0.16, 0.475, "Pre mean", va="center", fontsize=9)
    axLegend.add_patch(plt.Rectangle((0.06, 0.32), 0.06, 0.05, color=LIGHT_BLUE))
    axLegend.text(0.16, 0.345, "Post mean", va="center", fontsize=9)
    axLegend.set_xlim(0, 1)
    axLegend.set_ylim(0, 1)

    for col, (panel, monkey, area, label) in enumerate(MONKEY_PANELS):
        ax = fig.add_subplot(gs[1, col])
        reward_panel(ax, reward, reward_tests, monkey, area, label)

    fig.subplots_adjust(left=0.06, right=0.99, top=0.92, bottom=0.12, hspace=0.55, wspace=0.45)
    save_figure(fig, "Fig4_frequency_specific_decomposition")


if __name__ == "__main__":
    main()
