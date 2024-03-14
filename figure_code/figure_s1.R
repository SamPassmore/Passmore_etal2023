## This file makes figure S1

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
})

cantometrics = read.csv('processed_data/cleaned_cantometrics.csv')

cantometrics_summary = cantometrics %>% 
  group_by(society_id) %>% 
  count()

p1 = ggplot(cantometrics_summary, aes(x = n)) + 
  geom_histogram(bins = 70) + 
  ylab("Count") + 
  xlab("Number of songs per society")

ggsave(filename = "figures/figure_s1.png", plot = p1, height = 8)
