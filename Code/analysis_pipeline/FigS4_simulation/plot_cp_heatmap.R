# Purpose: Plot CP heatmaps (Pre vs Post) with fixed contour levels and a 0.51 outline.
# Notes: Expects CP matrices shaped [time x frequency] with 36 time bins and 149 freq bins (cols 4:152).

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
})

## ---- PATHS (EDIT HERE) ----
# Example input and output paths (replace with your own)
dots_df_path     <- "D:/NeuroProject/CP_analysis/data/pre_condition.csv"
dotsMusc_df_path <- "D:/NeuroProject/CP_analysis/data/post_condition.csv"
freq_path        <- "D:/NeuroProject/CP_analysis/metadata/freqscale.csv"
output_dir       <- "D:/NeuroProject/CP_analysis/results"
output_basename  <- "cp_heatmap_example"
## ---------------------------

# Read CP matrices, keep columns 4:152
dots_df     <- read_csv(dots_df_path, col_names = FALSE, show_col_types = FALSE)     |> select(4:152)
dotsMusc_df <- read_csv(dotsMusc_df_path, col_names = FALSE, show_col_types = FALSE) |> select(4:152)

# Frequency labels (row 1, columns 4:152 from your freqscale file)
freq <- read_csv(freq_path, col_names = FALSE, show_col_types = FALSE) |> 
  select(4:152) |> slice(1) |> unlist() |> as.numeric()

time <- seq(from = -200, to = 500, length.out = nrow(dots_df))

colnames(dots_df)     <- freq
colnames(dotsMusc_df) <- freq
rownames(dots_df)     <- time
rownames(dotsMusc_df) <- time

dots_long <- dots_df |>
  as.data.frame() |>
  tibble::rownames_to_column(var = "Time") |>
  pivot_longer(-Time, names_to = "Frequency", values_to = "absCP") |>
  mutate(Dataset = "Pre-Inactivation")

dotsMusc_long <- dotsMusc_df |>
  as.data.frame() |>
  tibble::rownames_to_column(var = "Time") |>
  pivot_longer(-Time, names_to = "Frequency", values_to = "absCP") |>
  mutate(Dataset = "Post-Inactivation")

combined_data <- bind_rows(dots_long, dotsMusc_long) |>
  mutate(
    Time        = as.numeric(Time),
    Frequency   = as.numeric(Frequency),
    logFrequency= log10(Frequency),
    absCP       = as.numeric(absCP),
    Dataset     = factor(Dataset, levels = c("Pre-Inactivation", "Post-Inactivation"))
  )

contour_breaks <- seq(0.45, 0.55, by = 0.01)
dummy_plot <- ggplot(combined_data, aes(x = Time, y = logFrequency, z = absCP)) +
  geom_contour_filled(breaks = contour_breaks)
actual_levels <- levels(ggplot_build(dummy_plot)$data[[1]]$level)
fixed_colors  <- grDevices::colorRampPalette(c("cyan", "navyblue", "darkgoldenrod1"))(length(actual_levels))
named_palette <- setNames(fixed_colors, actual_levels)

freq_ticks  <- c(5, 12, 30, 70, 150)
time_ticks  <- c(-200, 0, 70, 270, 370)

heatmap_plot <- ggplot(combined_data, aes(x = Time, y = logFrequency, z = absCP)) +
  geom_contour_filled(aes(fill = ..level..), breaks = contour_breaks, linewidth = 0) +
  geom_contour(aes(z = absCP), breaks = c(0.51), color = "black", linewidth = 1.1) +
  facet_wrap(~ Dataset, ncol = 1) +
  scale_y_continuous(
    breaks = log10(freq_ticks),
    labels = as.character(freq_ticks)
  ) +
  scale_x_continuous(
    limits = c(-200, 450),
    breaks = time_ticks,
    labels = as.character(time_ticks)
  ) +
  scale_fill_manual(
    values = named_palette,
    name = "LFP-based CP Level",
    guide = guide_legend(reverse = TRUE)
  ) +
  geom_hline(yintercept = log10(freq_ticks), linetype = "dotted", color = "darkgray") +
  geom_vline(xintercept = time_ticks, linetype = "dotted", color = "darkgray") +
  labs(x = "Time (ms), relative to stimulus onset", y = "Log Frequency (Hz)") +
  theme_minimal(base_family = "Arial") +
  theme(
    axis.text   = element_text(size = 12, color = "black"),
    axis.title  = element_text(size = 12, color = "black"),
    legend.title= element_text(face = "bold", size = 12, color = "black"),
    legend.text = element_text(size = 12, color = "black"),
    strip.text  = element_text(face = "bold", size = 12, color = "black"),
    panel.grid.major = element_blank(),
    panel.grid.minor = element_blank()
  )

print(heatmap_plot)

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
output_png <- file.path(output_dir, paste0(output_basename, ".png"))
output_pdf <- file.path(output_dir, paste0(output_basename, ".pdf"))

ggsave(output_png, heatmap_plot, width = 8, height = 8, dpi = 300)
grDevices::cairo_pdf(filename = output_pdf, width = 8, height = 8)
print(heatmap_plot)
dev.off()
