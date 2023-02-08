#!/usr/bin/env Rscript

# Phist calculation
suppressPackageStartupMessages({
  library(haplotypes)
  library(optparse)
  library(phangorn)
  library(dplyr)
  library(stringr)
})

# start time
start_time <- Sys.time()

#### terminal commands ####
option_list <- list (
  make_option(c("-d", "--datafile"),
              help="Data to use", 
              default = "processed_data/latent_variablemodelcantometrics_2songs.csv"),
  make_option(c("-r", "--response"),
              help="Response variable to analyse",
              default = "differentiation")
)

parser = OptionParser(option_list=option_list)
arguments = parse_args (parser, positional_arguments=TRUE)
opt = arguments$options

response = opt$response
datafile = opt$datafile

# cantometrics data
cantometrics = read.csv(datafile)

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

# make distance matrix
dist_data = cantometrics[,variables]
musical_dist = dist(dist_data, method = 'euclidean') + 0.000001

# Excoffier et al. (1992) suggest using a squared distance matrix for PhiST calculations
musical_dist = musical_dist^2

phist = haplotypes::pairPhiST(musical_dist,
                              cantometrics$society_id,
                              nperm = 99,
                              showprogbar = TRUE
)

phist_matrix = phist$PhiST

dataset = tools::file_path_sans_ext(basename(datafile)) 
output = paste0('results/phist/', response, "_amova_", dataset, ".nex")
cat("\nResults are stored in", output)

write.nexus.dist(phist_matrix, output)

end_time <- Sys.time()
print(end_time - start_time)



