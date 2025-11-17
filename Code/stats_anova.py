# -*- coding: utf-8 -*-
"""
Run mixed-effects ANOVA from saved source data (anova_df_%s.csv)

This script performs:
- Mixed linear model: CP ~ epoch * condition + (1|monkey)
- One model per frequency band

Author: yhou30
"""

import pandas as pd
import statsmodels.formula.api as smf
import os

# === Load source data ===
band_name = "high_gamma"   # ← Change this to analyze another band
input_dir = r"C:\Users\yhou30\Desktop\project_2\github2\data"

filepath = os.path.join(input_dir, f"anova_df_{band_name}.csv")
anova_df = pd.read_csv(filepath)

# Convert columns to categorical
for col in ["epoch", "condition", "area", "band", "monkey"]:
    anova_df[col] = anova_df[col].astype("category")

print("Loaded ANOVA-level source data:")
print(anova_df.head())

# === Run ANOVA model ===
print(f"\n=== Mixed ANOVA (epoch × condition) for {band_name} ===")

model = smf.mixedlm("CP ~ epoch * condition", 
                    data=anova_df, 
                    groups=anova_df["monkey"])

result = model.fit(reml=False)
print(result.summary())
