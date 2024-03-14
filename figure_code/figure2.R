## Figure 2

suppressPackageStartupMessages({
  library(ggplot2)
  library(dplyr)
  library(patchwork)
  library(ggridges)
  library(tidyr)
})

#### Data ####
cantometrics = read.csv('processed_data/latent_variablemodelcantometrics_2songs.csv')

# Get language family data by Language family name
language_df1 = cantometrics %>% 
  dplyr::filter(Language_family == "Atlantic-Congo")
language_df2 = cantometrics %>% 
  dplyr::filter(Language_family == "Sino-Tibetan")

# Get notable songs by song_id
notable_songs = c(398, 9260, 2559, 30063)
ns_data = cantometrics %>% 
  dplyr::filter(song_id %in% notable_songs) %>% 
  select(song_id, differentiation, dynamics, ornamentation, rhythm, tension)
ns_data$labels = LETTERS[1:nrow(ns_data)]

#### Plots ####
##### Rhythm & Ornamentation #####
# Dot plot for Rhythm all songs with labels for the notable songs
# Ornamentation is the x-axis for all plots. 
rhythm = ggplot(cantometrics, 
                aes(x = ornamentation, y = rhythm)) + 
  ggtitle("A) All 5,242 songs") + 
  xlab("Ornamentation") + 
  ylab("Rhythm") + 
  geom_point(alpha = 0.1) + 
  geom_label(data = ns_data,
             aes(x = ornamentation, y = rhythm,
                 label = labels),
             cex = 2.8) +
  theme_minimal()

# Topographical density plot for Rhythm & Ornamentation
base_rhythm = ggplot(cantometrics, 
                     aes(x = ornamentation, y = rhythm)) + 
  geom_density2d(
    alpha = 0.5, 
    col = "black"
  ) +
  theme_minimal()

# Overlay topographical plot with language family data
p_rjoin = base_rhythm + 
  ggtitle("B) Atlantic-Congo & Sino-Tibetan") + 
  xlab(element_blank()) + 
  ylab(element_blank()) + 
  geom_jitter(
    data = language_df1,
    aes(x = ornamentation, y = rhythm),
    color = "red",
    alpha = 0.5
  ) + 
  geom_jitter(
    data = language_df2,
    aes(x = ornamentation, y = rhythm),
    color = "blue",
    alpha = 0.5) +
  theme(legend.position = "bottom")

p2_rjoin = p_rjoin + 
  geom_point(data = cantometrics[cantometrics$society_id %in% c(21044, 12849),], 
             aes(x = ornamentation, y = rhythm, 
                 group = society_id, fill = Language_family),
             shape = 22, 
             size = 3) + 
  scale_fill_manual(values = c("red", "blue")) + 
  xlab("Ornamentation") + 
  theme(legend.position = "bottom", legend.title = element_blank())


output = rhythm + p2_rjoin

ggsave(output, filename = "figures/figure_2.pdf",
       width = 200, unit = "mm")
