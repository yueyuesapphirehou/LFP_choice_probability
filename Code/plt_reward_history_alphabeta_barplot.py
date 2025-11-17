# -*- coding: utf-8 -*-
"""
Plot Figure 4 (Reward history × inactivation condition)

@author: yhou30
"""

import pandas as pd
import numpy as np
import matplotlib.pyplot as plt
import seaborn as sns
import matplotlib

matplotlib.rcParams['pdf.fonttype'] = 42
sns.set(style="white", context="paper")

monkey = "ARY"  # options: ARY, LAV, CLU, YTU
source_path = fr"C:\Path\to\rewardhistory_{monkey}.csv"
df = pd.read_csv(source_path)

group_labels = ["Rewarded", "Non-rewarded"]
x = np.arange(2)
bar_width = 0.35

# Pre
means_pre = [
    df.loc[(df["reward"] == "rewarded") & (df["inactivation"] == "pre"), "mean_cp"].values[0],
    df.loc[(df["reward"] == "nonrewarded") & (df["inactivation"] == "pre"), "mean_cp"].values[0]
]
sems_pre = [
    df.loc[(df["reward"] == "rewarded") & (df["inactivation"] == "pre"), "sem_cp"].values[0],
    df.loc[(df["reward"] == "nonrewarded") & (df["inactivation"] == "pre"), "sem_cp"].values[0]
]

# Post
means_post = [
    df.loc[(df["reward"] == "rewarded") & (df["inactivation"] == "post"), "mean_cp"].values[0],
    df.loc[(df["reward"] == "nonrewarded") & (df["inactivation"] == "post"), "mean_cp"].values[0]
]
sems_post = [
    df.loc[(df["reward"] == "rewarded") & (df["inactivation"] == "post"), "sem_cp"].values[0],
    df.loc[(df["reward"] == "nonrewarded") & (df["inactivation"] == "post"), "sem_cp"].values[0]
]

plt.rcParams["font.family"] = "Arial"
fig, ax = plt.subplots(figsize=(3.5, 3))

ax.bar(x - bar_width/2, means_pre, bar_width, yerr=sems_pre,
       label="Pre-inactivation", color="black", alpha=0.7, capsize=4)

ax.bar(x + bar_width/2, means_post, bar_width, yerr=sems_post,
       label="Post-inactivation", color="#0072B2", alpha=0.7, capsize=4)

ax.axhline(0.5, linestyle="--", color="gray", linewidth=1)
ax.set_ylabel("Choice Probability (5–30 Hz)", fontsize=9)
ax.set_xticks(x)
ax.set_ylim(0.40, 0.55)
ax.set_xticklabels(group_labels, fontsize=9)
ax.tick_params(axis="y", labelsize=9)
ax.legend(frameon=False, fontsize=8, loc="upper left")

sns.despine()
plt.tight_layout()

plt.show()
