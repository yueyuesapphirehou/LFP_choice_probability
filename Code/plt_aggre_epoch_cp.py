# -*- coding: utf-8 -*-
"""
Plot CP values across behavioral epochs:

@author: yhou30
@date: 2025-10-28
"""

import pandas as pd
import matplotlib.pyplot as plt
import seaborn as sns
import os

# === 0. User Input: Choose Frequency Band ===
band_name = "lowgamma"   # options: "highgamma", "lowgamma", "alphabeta"

band_ranges = {
    "highgamma": (70, 150),
    "lowgamma": (30, 70),
    "alphabeta": (5, 30)
}

if band_name not in band_ranges:
    raise ValueError(f"Invalid band name '{band_name}'. Choose from {list(band_ranges.keys())}.")

fmin, fmax = band_ranges[band_name]

base_dir = r"C:\Users\yhou30\Desktop\project_2\main_results3\data"
summary_path = os.path.join(base_dir, "lowgamma_grand.csv")
df = pd.read_csv(summary_path)


sns.set(style="ticks", context="paper")
plt.figure(figsize=(4.2, 3))

epochs = df["epoch"].tolist()
x_pos = range(len(epochs))
plt.errorbar(x_pos, df["CP_pre"], yerr=df["CP_pre_sem"], fmt='-o',
             color='black', label='Pre-inactivation', capsize=3)
plt.errorbar(x_pos, df["CP_post"], yerr=df["CP_post_sem"], fmt='-o',
             color='#0072B2', label='Post-inactivation', capsize=3)
plt.xticks(x_pos, epochs, fontsize=9)
plt.ylabel("Choice Probability", fontsize=10)
plt.title(f"CP Across Epochs ({band_name.upper()} {fmin}-{fmax} Hz)", fontsize=10)
plt.axhline(0.5, linestyle='--', color='gray', linewidth=1)
plt.legend(frameon=False, loc='upper left')
sns.despine()

