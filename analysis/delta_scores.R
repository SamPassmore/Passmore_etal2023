#!/usr/bin/env Rscript

### script that takes a text file as input containing a lavaan model
### 
### Fits the model
### 
### Outputs the latent variables and fit statistics

suppressPackageStartupMessages({
  library(phylogemetric)
  library(optparse)
  library(dplyr)
  library(stringr)
})

set.seed(159)

#### options ####

option_list <- list( 
  make_option(c("-d", "--datafile"), action="store", 
              type="character", 
              default = 'processed_data/latent_variablemodelcantometrics_2songs.csv', 
              help="Data file to use"),
  make_option(c("-r", "--response"),
              help="Response variable to analyse",
              default = "differentiation"),
  make_option(c("-s", "--societies"),
              help="Max number of societies to analyse",
              default = "50")
)

opt = parse_args(OptionParser(option_list=option_list))

datafile = opt$datafile
response = opt$response
n_societies = as.numeric(opt$societies)

#### data ####
cantometrics = read.csv(datafile)
cantometric_societies = cantometrics %>% 
  distinct(society_id, Region, Division)

# Get constructed variables
# get variables
subset = word(basename(datafile), 3, sep = "_")
parestimates = read.csv(paste0("results/lavaanparameterestimates_cantometrics_", subset))

if(response == "all"){
  variables = colnames(cantometrics)[str_detect(colnames(cantometrics), "line_")] 
} else {
  variables = parestimates %>% 
    filter(lhs == response) %>% 
    filter(str_detect(rhs, "line_")) %>% 
    pull(rhs)
}

#### analysis ####

## Calculate delta scores for three major regions 
## Ideally we would calculate this for the entire dataset, but this would take too much computational time

# Identify the top three Regions
# cantometric_societies %>% 
#   group_by(Region) %>% 
#   summarise(n_count = n()) %>% 
#   arrange(desc(n_count))

# Region          n_count
# <chr>             <int>
#   1 Africa              143
# 2 Europe              115
# 3 Oceania              87
# 4 North America        76
# 5 Southeast Asia       64
# 6 South America        55
# 7 South Asia           45
# 8 Central America      39
# 9 Western Asia         31
# 10 East Asia            28
# 11 North Eurasia        13
# 12 Central Asia         12
# 13 Australia            11

africa = cantometric_societies %>% 
  filter(Region == "Africa")
europe = cantometric_societies %>% 
  filter(Region == "Europe")
oceania = cantometric_societies %>% 
  filter(Region == "Oceania")

african_data = cantometrics %>%
  filter(society_id %in% africa$society_id) %>%
  group_by(society_id) %>% 
  summarise(
    society_id = first(society_id),
    n_songs = n(),
    across(variables, ~ mean(.x, na.rm = TRUE))) %>% 
  top_n(n_societies, wt = n_songs)

ad = african_data[,variables]
ad_taxa = as.character(african_data$society_id)
rownames(ad) = ad_taxa

africa_delta = delta_score(ad, ad_taxa, method = "euclidean", n_cores = detectCores() - 1)

#### Oceania ####
oceania_data = cantometrics %>%
  filter(society_id %in% oceania$society_id) %>%
  group_by(society_id) %>% 
  summarise(
    society_id = first(society_id),
    n_songs = n(),
    across(variables, ~ mean(.x, na.rm = TRUE))
  ) %>% 
  top_n(n_societies, wt = n_songs)

oc = oceania_data[,variables]
oc_taxa = as.character(oceania_data$society_id)
rownames(oc) = oc_taxa

oceania_delta = delta_score(oc, oc_taxa, method = "euclidean", n_cores = detectCores() - 1)

#### European ####
european_data = cantometrics %>%
  filter(society_id %in% europe$society_id) %>%
  group_by(society_id) %>% 
  summarise(
    society_id = first(society_id),
    n_songs = n(),
    across(variables, ~ mean(.x, na.rm = TRUE))
  ) %>% 
  top_n(n_societies, wt = n_songs)

eu = european_data[,variables]
eu_taxa = as.character(european_data$society_id)
rownames(eu) = eu_taxa

european_delta = delta_score(eu, eu_taxa, method = "euclidean", n_cores = detectCores() - 1)

format_output = function(x, location = "africa"){
  df = data.frame(societies = names(x$delta_taxon_scores),
                  scores = x$delta_taxon_scores)
  
  df$location = location
  df = rbind(df, c("overall_score", x$delta_score, location))
  
  df
}

africa = format_output(africa_delta, "africa")
oceania = format_output(oceania_delta, "oceania")
euro = format_output(european_delta, "europe")

output = rbind(africa, oceania, euro)

label = tools::file_path_sans_ext(basename(datafile)) 
write.csv(output, file = paste0("results/delta/", label, "_", response, "_deltascores.csv"))
