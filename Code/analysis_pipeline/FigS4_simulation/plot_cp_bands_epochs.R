# Purpose: Average CP within frequency bands × time epochs, plot Pre vs Post with error bars.
# Notes: Expects CP matrices shaped [time x frequency].

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(tidyr)
  library(readr)
})

## ---- PATHS (EDIT HERE) ----
freq_path   <- "D:/NeuroProject/CP_analysis/metadata/freqscale.csv"
dots_pre    <- "D:/NeuroProject/CP_analysis/data/pre_condition.csv"
dots_post   <- "D:/NeuroProject/CP_analysis/data/post_condition.csv"
output_dir  <- "D:/NeuroProject/CP_analysis/results"
output_base <- "cp_bands_epochs_example"
## ---------------------------

# Frequency vector (from file: row 1, cols 4:152)
freq <- read_csv(freq_path, col_names = FALSE, show_col_types = FALSE) |>
  select(4:152) |> slice(1) |> unlist() |> as.numeric()

# Time vector (36 bins from -200 to 500 ms)
time <- seq(from = -200, to = 500, length.out = 36)

# Define bands and epochs
freq_bands <- list(
  list(min = 5,   max = 12,  label = "Alpha (5–12 Hz)"),
  list(min = 12,  max = 30,  label = "Beta (12–30 Hz)"),
  list(min = 30,  max = 70,  label = "Low Gamma (30–70 Hz)"),
  list(min = 70,  max = 150, label = "High Gamma (70–150 Hz)")
)

time_epochs <- list(
  list(min = -200, max = 70,  label = "Baseline"),
  list(min = 70,   max = 270, label = "Stimulus"),
  list(min = 270,  max = 370, label = "Delay")
)

group_and_average <- function(df) {
  out <- data.frame()
  for (band in freq_bands) {
    for (ep in time_epochs) {
      subset_df <- df[time >= ep$min & time <= ep$max,
                      freq >= band$min & freq <= band$max]
      avg <- mean(as.matrix(subset_df), na.rm = TRUE)
      sem <- sd(as.matrix(subset_df), na.rm = TRUE) / sqrt(length(subset_df))
      out <- rbind(out,
                   data.frame(FrequencyBand = band$label,
                              Epoch         = ep$label,
                              CP            = avg,
                              CI            = sem))
    }
  }
  out
}

pre_df  <- read_csv(dots_pre,  col_names = FALSE, show_col_types = FALSE)
post_df <- read_csv(dots_post, col_names = FALSE, show_col_types = FALSE)

pre_avg  <- group_and_average(pre_df)  |> mutate(Dataset = "Pre-Inactivation")
post_avg <- group_and_average(post_df) |> mutate(Dataset = "Post-Inactivation")

combined <- bind_rows(pre_avg, post_avg) |>
  mutate(
    Dataset       = factor(Dataset, levels = c("Pre-Inactivation","Post-Inactivation")),
    FrequencyBand = factor(FrequencyBand, levels = sapply(freq_bands, `[[`, "label")),
    Epoch         = factor(Epoch, levels = sapply(time_epochs, `[[`, "label"))
  )

my_plot <- ggplot(combined, aes(x = Epoch, y = CP,
                                color = Dataset,
                                group = interaction(Dataset, FrequencyBand))) +
  geom_hline(yintercept = 0.5, linetype = "dotted", color = "#3b3b3b", size = 1.1) +
  geom_errorbar(aes(ymin = CP - CI, ymax = CP + CI),
                width = 0.2, position = position_dodge(width = 0.3)) +
  geom_point(position = position_dodge(width = 0.3), size = 1.8) +
  geom_line(position = position_dodge(width = 0.3), size = 1.2) +
  facet_wrap(~ FrequencyBand, ncol = 4, scales = "free_y") +
  ylim(c(0.48, 0.53)) +
  scale_color_manual(values = c("Pre-Inactivation"="#08272C",
                                "Post-Inactivation"="#6495C4")) +
  labs(y = "LFP-based CP", x = NULL) +
  theme_minimal(base_size = 14) +
  theme(
    axis.text.x  = element_text(color="black"),
    axis.text.y  = element_text(color="black"),
    axis.title.y = element_text(size=16, color="black"),
    strip.text   = element_text(size=14, color="black"),
    legend.position = "bottom",
    legend.title = element_text(size=14, face="bold"),
    legend.text  = element_text(size=12),
    panel.grid   = element_blank()
  )

print(my_plot)

if (!dir.exists(output_dir)) dir.create(output_dir, recursive = TRUE)
ggsave(file.path(output_dir, paste0(output_base, ".png")),
       my_plot, width=14, height=8, dpi=300)
grDevices::cairo_pdf(file.path(output_dir, paste0(output_base, ".pdf")),
                     width=14, height=8); print(my_plot); dev.off()
