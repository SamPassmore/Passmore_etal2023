# delta comparisons
library(tidyr)
library(ggplot2)
library(purrr)

files = list.files('results/delta/', pattern = "deltasummary.csv", full.names = TRUE)

data = lapply(files, read.csv)

data_comparison = lapply(data, function(d){
  pivot_longer(d, cols = c("africa", "oceania", "europe"))
})
names(data_comparison) = c("10song", "2song", "sccs")

data_combined = map_df(data_comparison, ~as.data.frame(.x), .id = "dataset")
data_combined$dataset = factor(data_combined$dataset, levels = c("2song", "10song", "sccs"))

ggplot(data_combined, aes(y = value, x = dataset, col = id, group = id)) + 
  geom_point() + 
  geom_line() + 
  xlab("Dataset") + 
  ylab("Delta Score") + 
  facet_wrap(~name) + 
  theme_classic()

