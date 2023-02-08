#!/usr/bin/env Rscript

# Script comparing the complete latent variable model with the reliability reduced model
suppressPackageStartupMessages({
  library(dplyr)
  library(ggplot2)
  library(ggpubr)
  library(purrr)
})

#### Data ####
cat("Comparing Full and Reliability restricted Latent models....")

full_model = read.csv('processed_data/latent_variablemodelcantometrics_2songs.csv')
restricted_model = read.csv('processed_data/latent_variablemodel_highreliabilitycantometrics_2songs.csv')

# Select variables of interest
full_model = full_model %>% 
  select(song_id, society_id, differentiation, ornamentation, rhythm, dynamics, tension)

restricted_model = restricted_model %>% 
  select(song_id, society_id, differentiation, ornamentation, line_11, dynamics, line_29)

combined_df = left_join(full_model, restricted_model, by = c("song_id", "society_id"), suffix = c(".full", ".rest"))

#### Correlation table ####
correlation = list()
for(i in 1:5){
  correlation[[i]] = 
    cor.test(full_model[,i+2],
           restricted_model[,i+2])
}

cor.value = lapply(correlation, "[[", "estimate") %>% 
  unlist() %>% 
  round(., 2)
p.value = lapply(correlation, "[[", "p.value") %>% 
  unlist() %>% 
  round(., 4)
cor.table = data.frame(full = c("Articulation", "Ornamentation", "Rhythm", "Dynamics", "Tension"),
                       restricted = c("Articulation", "Ornamentation", "Line 11", "Dynamics", "Line 29"),
                       correlation = cor.value,
                       p = p.value)
cor.table$p = ifelse(cor.table$p == 0, "<0.001", cor.table$p)

output_file1 = 'results/latentmodel_comparison.csv'
cat("Results saved at", output_file1)
write.csv(cor.table, output_file1, row.names = FALSE)

#### Plots + Correlations ####
plot_comparison = function(x, y, main){
  require(ggplot2)
  df = data.frame(x = combined_df[,x],
                  y = combined_df[,y])
  ggplot(df, aes(x = x, y = y)) + 
    geom_point() + 
    xlab("Full latent model") + 
    ylab("Restricted latent model") + 
    stat_cor(method="pearson") + 
    ggtitle(main) + 
    theme_classic()
}

# Articulation
p1 = plot_comparison("differentiation.full", "differentiation.rest", "Articulation")
# Ornamentation
p2 = plot_comparison("ornamentation.full", "ornamentation.rest", "Ornamentation")
# Rhythm
p3 = plot_comparison("rhythm", "line_11", "Rhythm vs Line 11")
# Dynamics
p4 = plot_comparison("dynamics.full", "dynamics.rest", "Dynamics")
# Tension
p5 = plot_comparison("tension", "line_29", "Tension vs Line 29")

# save ggplots 
ggsave(plot = p1, filename = "figures/articulation_comparison.png", width = 210, units = "mm")
ggsave(plot = p2, filename = "figures/ornamentation_comparison.png", width = 210, units = "mm")
ggsave(plot = p3, filename = "figures/rhythm_comparison.png", width = 210, units = "mm")
ggsave(plot = p4, filename = "figures/dynamics_comparison.png", width = 210, units = "mm")
ggsave(plot = p5, filename = "figures/tension_comparison.png", width = 210, units = "mm")


#### Compare Different samples ####

cat("Comparing different samples of Cantometrics....")

songs_2 = read.csv('processed_data/latent_variablemodelcantometrics_2songs.csv') %>% 
  select(song_id, society_id, differentiation, ornamentation, rhythm, dynamics, tension)
songs_10 = read.csv('processed_data/latent_variablemodelcantometrics_10songs.csv') %>% 
  select(song_id, society_id, differentiation, ornamentation, rhythm, dynamics, tension)
songs_sccs = read.csv('processed_data/latent_variablemodelcantometrics_sccs.csv') %>% 
  select(song_id, society_id, differentiation, ornamentation, rhythm, dynamics, tension)

lavar_names = c("differentiation", "ornamentation", "rhythm", "dynamics", "tension")

df_1 = left_join(songs_2, songs_10, by = c("song_id", "society_id"), suffix = c(".2", ".10"))
df_2 = left_join(songs_2, songs_sccs, by = c("song_id", "society_id"), suffix = c(".2", ".sccs"))
df_3 = left_join(songs_10, songs_sccs, by = c("song_id", "society_id"), suffix = c(".10", ".sccs"))

compare_1 = list()
compare_2 = list()
compare_3 = list()
for(i in seq_along(lavar_names)){
  var = lavar_names[i]
  
  v1 = paste0(var, ".2")
  v2 = paste0(var, ".10")
  v3 = paste0(var, ".sccs")
  
  compare_1[[i]] = cor.test(df_1[,v1], df_1[,v2])
  compare_2[[i]] = cor.test(df_2[,v1], df_2[,v3])
  compare_3[[i]] = cor.test(df_3[,v2], df_3[,v3])
}

compare = list(compare_1, compare_2, compare_3)

cor.value = lapply(compare, function(x){
  lapply(x, "[[", "estimate") %>% 
    unlist() %>% 
    round(., 3)
})
p.value = lapply(compare, function(x){
  lapply(x, "[[", "p.value") %>% 
    unlist() %>% 
    round(., 4)
})


correlation_table = map2(cor.value, p.value, cbind) %>% 
  do.call(rbind, .) %>%
  as.data.frame()

correlation_table$variable = rep(lavar_names, each = 3)
correlation_table$comparison = rep(c("2 vs 10", "2 vs SCCS", "10 vs SCCS"), times = 5)

correlation_table = correlation_table %>%
  select(variable, comparison, pearson = V1, p = V2)

correlation_table$p = ifelse(correlation_table$p == 0, "<0.001", correlation_table$p)

output_file = 'results/latentsample_comparison.csv'
cat("Results saved at", output_file, "\n")
write.csv(correlation_table, file = output_file, row.names = FALSE)

