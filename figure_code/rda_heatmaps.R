suppressPackageStartupMessages({
  library(tidyr)
  library(ggplot2)
  library(stringr)
  library(dplyr)
})

rda_files = list.files(path = "results/rda/", pattern = "*_3wayRDA.csv", full.names = TRUE)
rda_files = rda_files[!str_detect(rda_files, "sensitivity")]
rda_files = rda_files[str_detect(rda_files, "2songs")]

rda_dfs = lapply(rda_files, read.csv)

nmes = str_split(rda_files, "_")
nmes = lapply(nmes, "[[", 2) %>% unlist()

names(rda_dfs) = nmes
rda_df = bind_rows(rda_dfs, .id = "variable")

rda_df$variable = recode(rda_df$variable, SoutheastAsia = "Southeast Asia", world = "All")
rda_df$variable = factor(rda_df$variable, levels = c("All", "Africa", "Europe", "Southeast Asia"))

rda_df$explanatory = paste(substr(rda_df$explanatory, 1, 3), 
                           substr(rda_df$constraint, 1, 3), sep = " ctrl ")

rda_df$response = str_to_title(rda_df$response)
rda_df$response = ifelse(rda_df$response == "Differentiation", "Articulation", rda_df$response)

rda_df$adj.r2 = ifelse(rda_df$adj.r2 < 0, 0, rda_df$adj.r2)

b = 10
p1 = ggplot(rda_df, aes(explanatory, response)) +
  geom_tile(aes(fill = adj.r2)) + 
  geom_text(aes(label = round(adj.r2, 2))) +
  scale_fill_gradient(limits = c(0,1),
                      low = "white", high = "red",
                      breaks=b, labels=format(b)) +
  theme_minimal() + 
  ylab("") + xlab("") + 
  theme(panel.grid.major = element_blank(), panel.grid.minor = element_blank(),
        axis.text.x = element_text(angle = 45, vjust = 0.5, hjust=1)) + 
  facet_wrap(~variable)

ggsave("figures/heatmap_figure.jpg", plot = p1, bg="white", height = 140, width = 200, units = "mm")
