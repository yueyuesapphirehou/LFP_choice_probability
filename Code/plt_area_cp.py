# -*- coding: utf-8 -*-
"""
Plot CP with SEM + individual session traces from source data
@author: yhou30
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os
import matplotlib
matplotlib.rcParams['pdf.fonttype'] = 42 

session_dir = 
source_path = os.path.join(session_dir, "alphabeta_MT")
df = pd.read_csv(source_path)

plot_times = df["time_ms"].values
n_sessions = len([col for col in df.columns if col.startswith("CP_pre_s")])-1

sns.set(style="ticks", context="paper")
plt.figure(figsize=(4, 3))

plt.plot(plot_times, df["CP_pre"], color="black", linewidth=2, label="Pre-inactivation")
plt.fill_between(plot_times,
                 df["CP_pre"] - df["CP_pre_sem"],
                 df["CP_pre"] + df["CP_pre_sem"],
                 color="black", alpha=0.2)

plt.plot(plot_times, df["CP_post"], color="#0072B2", linewidth=2, label="Post-inactivation")
plt.fill_between(plot_times,
                 df["CP_post"] - df["CP_post_sem"],
                 df["CP_post"] + df["CP_post_sem"],
                 color="#0072B2", alpha=0.2)

# === 5. Labels and Save ===
plt.axhline(0.5, linestyle="--", color="gray", linewidth=1)
plt.axvline(0, linestyle="--", color="gray", linewidth=1)
plt.xlabel("Time from stimulus onset (ms)")
plt.ylabel("Choice Probability")
plt.xlim(-200, 400)

plt.legend(frameon=False)
sns.despine()
plt.tight_layout()

