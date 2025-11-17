# -*- coding: utf-8 -*-
"""
Monkey-wise CP traces, plotted individually (V4 vs MT)
@author: yhou30
@date: 2025-10-13
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

session_dir = 
source_path = os.path.join(session_dir, "alphabeta_mkywise.csv")
df = pd.read_csv(source_path)
sns.set(style="ticks", context="paper")

monkey_configs = [
    ('LAV', 'V4'),
    ('ARY', 'V4'),
    ('CLU', 'MT'),
    ('YTU', 'MT')
]

for monkey_id, area in monkey_configs:
    sub = df[df["monkey"] == monkey_id]

    plt.figure(figsize=(3.2, 2.4))
    plt.plot(sub["time_ms"], sub["CP_pre"], color="black", linewidth=1.5, label="Pre")
    plt.fill_between(sub["time_ms"],
                     sub["CP_pre"] - sub["CP_pre_sem"],
                     sub["CP_pre"] + sub["CP_pre_sem"],
                     color="black", alpha=0.2)

    plt.plot(sub["time_ms"], sub["CP_post"], color="#0072B2", linewidth=1.5, label="Post")
    plt.fill_between(sub["time_ms"],
                     sub["CP_post"] - sub["CP_post_sem"],
                     sub["CP_post"] + sub["CP_post_sem"],
                     color="#0072B2", alpha=0.2)

    plt.axhline(0.5, linestyle="--", color="gray", linewidth=1)
    plt.title(f"{monkey_id} ({area})", fontsize=9)
    plt.xlabel("Time (ms)", fontsize=8)
    plt.ylabel("Choice Prob.", fontsize=8)
    plt.legend(frameon=False, loc="upper right", fontsize=7)
    plt.xticks(fontsize=8)
    plt.yticks(fontsize=8)
    sns.despine()

