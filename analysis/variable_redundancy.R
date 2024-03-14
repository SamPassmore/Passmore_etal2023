#!/usr/bin/env Rscript
## This script creates fig s4. 


suppressPackageStartupMessages({
  library(psych)
  library(ggplot2)
  library(patchwork)
  library(optparse)
  library(stringr)
})

#### Command line Parameters ####
option_list = list(
  make_option(
    c("-f", "--file"),
    type = "character",
    default = "processed_data/cleaned_cantometrics.csv",
    help = "dataset file name",
    metavar = "character"
  )
)

opt_parser = OptionParser(option_list=option_list)
opt = parse_args(opt_parser)

filename = opt$file

#### Read in Data ####
cantometrics = read.csv(filename)

# identify cantometric variables
line_vars = str_detect(colnames(cantometrics), "line_")
lines = cantometrics[,line_vars]

canto_pca = principal(lines, 
                      nfactors = 6, 
                      rotate = "varimax")

# First two principle components
pca_values = data.frame(canto_pca$scores[,1:2], lines$line_2, lines$line_1)
pca_values$instrumental_solo = ifelse(pca_values$lines.line_2 == 1, "Solo Instrument", "Multiple Instruments")
pca_values$singing_solo = ifelse(pca_values$lines.line_2 %in% 1:3, "Solo Singer", "Multiple Singers")

p1 = ggplot(pca_values, aes(x = singing_solo, y = RC2, fill = instrumental_solo)) +
  geom_boxplot() + 
  geom_jitter(alpha = 0.1) +
  xlab("") + 
  ylab("PC1 (25% Proportion Explained)") + 
  theme_classic() + 
  theme(legend.position = "none") 
  

p2 = ggplot(pca_values, aes(x = singing_solo, y = RC2, fill = singing_solo)) +
  geom_boxplot() + 
  geom_jitter(alpha = 0.1) +
  xlab("") + 
  ylab("PC1 (23% Proportion Explained)") + 
  theme_classic() + 
  theme(legend.position = "none") 
  

p3 = p1 + p2 

ggsave(filename = "figures/fig_s4.png", plot = p3, height = 6)
