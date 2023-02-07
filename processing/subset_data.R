# make data subsets
suppressPackageStartupMessages({
  library(dplyr)
  library(assertthat)
})


describe_sample = function(x, name){
  n_songs = nrow(x)
  n_society = length(unique(x$society_id))
  cat(
    "There are", n_songs, "songs from", n_society, "societies in the", name ,"dataset.\n"
  )
}

cantometrics_data = read.csv('processed_data/paired_data.csv')

cantometrics_data = cantometrics_data %>% 
  add_count(society_id)

#### All societies with 2 songs or more ####
cantometrics_twosongs = cantometrics_data %>% 
  dplyr::filter(n >= 2)

x = assert_that(all(cantometrics_twosongs$n >=2))

describe_sample(cantometrics_twosongs, "2+ songs")

write.csv(cantometrics_twosongs, 'processed_data/cantometrics_2songs.csv')

#### All societies with 10 songs or more ####
cantometrics_tensongs = cantometrics_data %>% 
  dplyr::filter(n >= 10)

x = assert_that(all(cantometrics_tensongs$n >= 10))

describe_sample(cantometrics_tensongs, "10+ songs")

write.csv(cantometrics_tensongs, 'processed_data/cantometrics_10songs.csv')

#### SCCS Sample ####

sccs = read.csv('https://raw.githubusercontent.com/D-PLACE/dplace-data/master/datasets/SCCS/societies.csv')

cantometrics_sccs = cantometrics_data %>% 
  filter(pairing.glottocode %in% sccs$glottocode)

describe_sample(cantometrics_sccs, "SCCS")

write.csv(cantometrics_sccs, 'processed_data/cantometrics_sccs.csv')

