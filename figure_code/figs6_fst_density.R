#!/usr/bin/env Rscript
## This script creates figure S6, and fig S11 - S16.

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(ggplot2)
  library(ggpubr)
  library(patchwork)
  library(reshape2)
})

articulation = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "DifferentiationDist", skip = 2)
ornamentation = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "OrnamentationDist", skip = 2)
rhythm = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "RhythmDist", skip = 2)
dynamics = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "DynamicsDist", skip = 2)
tension = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "TensionDist", skip = 2)
genetics = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "GeneticDist", skip = 2)
geography = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "GeographicDist", skip = 2)
language = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "LanguageDist", skip = 2)
musical = read_xlsx("data/latent_variablemodelcantometrics_2songsdistances.xlsx", sheet = "MusicalDist", skip = 2)

distances = list(articulation, ornamentation, rhythm, dynamics, tension, genetics)
distances = lapply(distances, function(x) as.numeric(x[lower.tri(x)]))
names(distances) = c("Articulation", "Ornamentation", "Rhythm", "Dynamics", "Tension", "Genetic_FST")

dist_long = bind_rows(distances, .id = "type")
dist_long = pivot_longer(dist_long, cols = everything())

p1 = ggplot(dist_long, aes(x = value, fill = name)) + 
  geom_density(alpha = 0.4) + 
  ylab("Density") + 
  xlab("FST Distance") + 
  theme_minimal() +
  theme(legend.position = "bottom", legend.title = element_blank())

ggsave(filename = "figures/figure_s6.png", plot = p1, height = 8)

## Fig S11 to S16
musical_phist = list(all = musical, articulation, ornamentation, rhythm, dynamics, tension)

# linguistic cophenteic distance
metadata = read_xlsx("data/id_matches.xlsx")
metadata = metadata[!duplicated(metadata$society_id),]
metadata = metadata[metadata$society_id %in% str_remove(colnames(musical), "X"),]
language = read.nexus("processed_data/pruned_edgetree.tree")

language = keep.tip(language, metadata$phylogeny.glottocode)
tree_dist = cophenetic.phylo(language)
tree_dist = data.frame(tree_dist)

colnames(tree_dist) = paste0("X", metadata$society_id[match(language$tip.label, metadata$phylogeny.glottocode)])

## add soceity rows
tree_dist$V118 = str_remove(colnames(tree_dist), "X")

tree_dist = tree_dist[,match(colnames(musical), colnames(tree_dist))]
tree_dist = tree_dist[match(musical$V118, tree_dist$V118),]

all(colnames(tree_dist) == colnames(musical))
all(tree_dist$V118 == musical$V118)

other_list = list(genetics = genetics, language = tree_dist, geography = geography)
# scale to 0 - 1
other_list = lapply(other_list, function(x){
  x = x[lower.tri(x)]
  x = as.numeric(x)
  x = x / max(x)
  x
})

title_vector = c("All Musical Variables", "Articulation", "Ornamentation", "Rhythm", "Dynamics", "Tension")
filename_vector = paste0("fig_S", 11:16, ".png")
for(i in seq_along(music_list)){
  dd = music_list[[i]]
  dd = dd[lower.tri(dd)]
  dd = as.numeric(dd)
  
  plot_list = other_list
  plot_list$music = dd
  
  plot_df = bind_rows(plot_list, .id = "type")
  
  p1 = ggplot(plot_df, aes(x = music, y = genetics)) + 
    geom_point(alpha = 0.2) + 
    geom_smooth(method = "lm", col = "red") + 
    stat_cor(method = "pearson", geom = "label", size = 6) + 
    theme_minimal(base_size = 20) +
    ylab("Distance") + 
    ggtitle("Genetic")
  
  p2 = ggplot(plot_df, aes(x = music, y = language)) + 
    geom_point(alpha = 0.2) + 
    geom_smooth(method = "lm", col = "red") + 
    stat_cor(method = "pearson", geom = "label", size = 6) + 
    theme_minimal(base_size = 20) +
    xlab("Musical FST Distance") +
    ggtitle("Linguistic") + 
    ylab(element_blank())
  
  p3 = ggplot(plot_df, aes(x = music, y = geography)) + 
    geom_point(alpha = 0.2) + 
    geom_smooth(method = "lm", col = "red") + 
    stat_cor(method = "pearson", geom = "label", size = 6) + 
    theme_minimal(base_size = 20) +
    ggtitle("Spatial") + 
    ylab(element_blank())

  pp = p1 + p2 + p3 + plot_annotation(title = title_vector[i], theme = theme(plot.title = element_text(size = 22)))
  
  ggsave(filename = paste0("figures/", filename_vector[i]), plot = pp, height = 6)
  
}
