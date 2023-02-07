#!/usr/bin/env Rscript
## This script takes a datafile as input and performs principal component analysis

suppressPackageStartupMessages({
  library(psych)
  library(optparse)
})

#### Command line Parameters ####
option_list = list(
  make_option(
    c("-f", "--file"),
    type = "character",
    default = "processed_data/cantometrics_2songs.csv",
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

# remove redundant lines
remove_lines = paste0("line_", c(1,2,3,5,6,9,8,12,14,13,22,26,27))
lines = lines[,!(colnames(lines) %in% remove_lines)]

canto_pca = principal(lines, 
                      nfactors = 6, 
                      rotate = "varimax")

png('figures/scree_plot.png')
scree(lines, 
      main = "Scree plot of Cantometric variables", 
      pc = TRUE,
      factors = FALSE)
dev.off()

scores = canto_pca$scores
cantometrics = cbind(cantometrics,scores)

## Plot PCA variables against latent variables
# Display figure for Pat
d3 = ggplot(cantometrics, aes(y = differentiation, x = RC1)) + 
  geom_point(alpha = 0.3) + 
  xlab("PC1: 21%") + 
  ylab("Articulation") +
  theme(text = element_text(size=15))
o1 = ggplot(cantometrics, aes(y = ornamentation, x = RC3)) + 
  geom_point(alpha = 0.3) + 
  xlab("PC3: 17%") + 
  ylab("Ornamentation") +
  theme(text = element_text(size=15))
r1 = ggplot(cantometrics, aes(y = rhythm, x = RC3)) + 
  geom_point(alpha = 0.3) + 
  xlab("PC3: 17%") + 
  ylab("Rhythm") +
  theme(text = element_text(size=15))
dy5 = ggplot(cantometrics, aes(y = dynamics, x = RC5)) + 
  geom_point(alpha = 0.3) + 
  xlab("PC6: 17%") + 
  ylab("Dynamics") +
  theme(text = element_text(size=15))
t2 = ggplot(cantometrics, aes(y = tension, x = RC2)) + 
  geom_point(alpha = 0.3) + 
  xlab("PC2: 20%") + 
  ylab("Tension") +
  theme(text = element_text(size=15))
or3 = ggplot(cantometrics, aes(y = organization, x = RC2)) + 
  geom_point(alpha = 0.3) + 
  xlab("PC2: 20%") + 
  ylab("Organization") +
  theme(text = element_text(size=15))

jpeg('figures/pca_comparison.jpeg', 
     width = 200, 
     height = 180,
     units = "mm", res = 72)
d3 + t2 + or3 + o1 +  r1 + dy5 + 
  plot_annotation(
    title = "Cantometric variables vs Principal Components")
dev.off()

#### Latent Comparison
# save loadings
descriptions = read.csv('raw/gjb/etc/variables.csv') 
descriptions$title = str_replace_all(descriptions$title,
                                     "\\s",
                                     " ")

loadings = data.frame(canto_pca$loadings[,1:ncol(canto_pca$loadings)])
loadings$line = rownames(loadings)
param_est = read.csv('results/lavaan_parameterestimates.csv')
param_est = param_est[1:20,]
param_est = param_est[,c("lhs", "rhs", "std.all")]
param_wide = pivot_wider(data = param_est, 
                         values_from = std.all, 
                         id_cols = rhs, 
                         names_from = lhs)

joined_data = left_join(loadings, param_wide, by = c("line" = "rhs"))

joined_data = joined_data %>% 
  left_join(., descriptions, by = c("line" = "id")) %>% 
  mutate(across(where(is.numeric), round, 2)) %>% 
  select(c("line", "title",
           "RC1", "differentiation",
           "RC2", "organization", "tension", 
           "RC3", "ornamentation", "rhythm", 
           "RC4", 
           "RC5", "dynamics"))

joined_data = joined_data[order(joined_data$line),]

write.csv(joined_data, 'results/principal_loadings.csv',
          row.names = FALSE, na = "")
