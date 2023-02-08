#!/usr/bin/env Rscript

# script for running AMOVA

suppressPackageStartupMessages({
  library(ade4)
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(assertthat)
  library(optparse)
  library(haplotypes)
})

#### terminal commands ####
option_list <- list (
  make_option(c("-d", "--datafile"),
              default = "processed_data/latent_variablemodelcantometrics_2songs.csv",
              help="Data to use"),
  make_option(c("-r", "--response"),
              help="Response variable to analyse",
              default = "differentiation"),
  make_option(c("-g", "--grouping"),
              help="Grouping variable to use (Region or Language_family)",
              default = "Language_family")
)

parser = OptionParser(option_list=option_list)
arguments = parse_args (parser, positional_arguments=TRUE)
opt = arguments$options

response = opt$response
datafile = opt$datafile
grouping = opt$grouping

cantometrics = read.csv(datafile)

# get variables for latent variable
subset = word(basename(datafile), 3, sep = "_")
parestimates = read.csv(paste0("results/lavaanparameterestimates_cantometrics_", subset))

variables = parestimates %>% 
  filter(lhs == response) %>% 
  filter(str_detect(rhs, "line_")) %>% 
  pull(rhs)

cat("Performing AMOVA for", response, "\nusing", grouping, "groups \nand", datafile, "\n")

#### Analysis ####

# Samples is a matrix which shows which song belongs to which society
sample_columns = cantometrics[,c("song_id", "society_id")]
samples_matrix = model.matrix(~ 0 + factor(society_id), 
                              sample_columns)
rownames(samples_matrix) = sample_columns$song_id
samples = data.frame(samples_matrix)

# Distance matrix 
dist_data = cantometrics[,variables]
# add a small value to avoid zero distance error
musical_dist = dist(dist_data, method = 'euclidean') + 0.000001

# structure shows what language family each society is in
structures = cantometrics %>% 
  distinct(society_id, .keep_all = TRUE) %>% 
  dplyr::select(all_of(grouping))
structures[,grouping] = factor(structures[,grouping])

# These tests are internal to the ade4::amova function
# But all return the same error message.
# They are external to help debug. 
x = assert_that(inherits(samples, "data.frame"))
x = assert_that(inherits(structures, "data.frame"))

m <- match(apply(structures, 2, 
                 function(x) length(x)), ncol(samples), 0)
x = assert_that(length(m[m == 1]) == ncol(structures))

m <- match(tapply(1:ncol(structures), 
                  as.factor(1:ncol(structures)), 
                  function(x) is.factor(structures[, x])), TRUE , 0)

x = assert_that(length(m[m == 1]) == ncol(structures))

results = amova(samples = samples, 
                distance = musical_dist, 
                structures = structures)

covariance = results$componentsofcovariance
covariance$response = response

dataset = basename(datafile)
output = paste0('results/amova/', response, "_amova_", dataset)

cat("Results saved at", output, "\n")

write.csv(covariance, file = output)


