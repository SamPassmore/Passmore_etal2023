## delta summary

suppressPackageStartupMessages({
  library(dplyr)
  library(stringr)
  library(purrr)
  library(tidyverse)
  library(optparse)
})

option_list <- list( 
  make_option(c("-d", "--datafile"), action="store", 
              type="character", 
              default = '2songs', 
              help="Data file to use")
)

opt = parse_args(OptionParser(option_list=option_list))

datafile = opt$datafile

files = list.files('results/delta/', pattern = paste0("_", datafile, "_"), full.names = TRUE)

data = lapply(files, read.csv)
names(data) = str_split(basename(files), "_") %>% 
  lapply(., "[", 4) %>% 
  unlist()

data = map_df(data, ~as.data.frame(.x), .id="id")

# overall table
output = data %>% 
  filter(societies == "overall_score") %>% 
  select(id, scores, location) %>% 
  pivot_wider(., values_from = scores, names_from = location)


write.csv(output, file = paste0("results/delta/", datafile, "_deltasummary.csv"), row.names = FALSE)
