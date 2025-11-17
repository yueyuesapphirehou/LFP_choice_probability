# -*- coding: utf-8 -*-
"""
Conduct CP-based Wilcoxon statistics

@author: yhou30
@date: 2025-10-29
"""
import pickle
import numpy as np
from scipy.stats import wilcoxon, ranksums

path_output = r"C:\Users\yhou30\Desktop\project_2\github2\data\cpstats_output_FreqName.pkl"
path_area   = r"C:\Users\yhou30\Desktop\project_2\github2\data\cpstats_area_raw_FreqName.pkl"

with open(path_output, "rb") as f:
    d1 = pickle.load(f)
output = d1["output"]
stats_rows = d1["stats_rows"]
stim_window = d1["stim_window"]

with open(path_area, "rb") as f:
    d2 = pickle.load(f)
area_raw_values = d2["area_raw_values"]
all_pre_means = d2["all_pre_means"]
all_post_means = d2["all_post_means"]

# === Monkey Level ===
for df_m, stat in zip(output, stats_rows):

    m = stat["monkey"]
    area = stat["area"]

    mask = (df_m["time_ms"] >= stim_window[0]) & (df_m["time_ms"] <= stim_window[1])

    mean_pre = df_m.loc[mask, "CP_pre"].mean()
    sem_pre = df_m.loc[mask, "CP_pre_sem"].mean()
    mean_post = df_m.loc[mask, "CP_post"].mean()
    sem_post = df_m.loc[mask, "CP_post_sem"].mean()

    print(f"\n===== Monkey {m} ({area}) =====")
    print(f"Pre:  {mean_pre:.3f} ± {sem_pre:.3f}, vs 0.5 → p={stat['p_pre_vs_0.5']:.4g}")
    print(f"Post: {mean_post:.3f} ± {sem_post:.3f}, vs 0.5 → p={stat['p_post_vs_0.5']:.4g}")
    print(f"Pre vs Post (rank-sum): p={stat['p_pre_vs_post']:.4g}")

# === Area Level ===
print("\n========== AREA-WISE SUMMARY ==========")

for area in ["V4", "MT"]:
    pre_vals = np.array(area_raw_values[area]["pre"])
    post_vals = np.array(area_raw_values[area]["post"])

    p_pre = wilcoxon(pre_vals - 0.5).pvalue
    p_post = wilcoxon(post_vals - 0.5).pvalue
    p_between = ranksums(pre_vals, post_vals).pvalue

    # Compute area-level means from per-monkey traces
    area_pre_means = []
    area_post_means = []

    for df_m, stat in zip(output, stats_rows):
        if stat["area"] == area:
            mask = (df_m["time_ms"] >= stim_window[0]) & (df_m["time_ms"] <= stim_window[1])
            area_pre_means.append(df_m.loc[mask, "CP_pre"].mean())
            area_post_means.append(df_m.loc[mask, "CP_post"].mean())

    mean_pre_area = np.mean(area_pre_means)
    sem_pre_area = np.std(area_pre_means, ddof=1)/np.sqrt(5)
    mean_post_area = np.mean(area_post_means)
    sem_post_area = np.std(area_post_means, ddof=1)/np.sqrt(5)

    print(f"\n===== {area} =====")
    print(f"Pre:  {mean_pre_area:.3f} ± {sem_pre_area:.3f}, vs 0.5 → p={p_pre:.4g}")
    print(f"Post: {mean_post_area:.3f} ± {sem_post_area:.3f}, vs 0.5 → p={p_post:.4g}")
    print(f"Pre vs Post: p = {p_between:.4g}")
