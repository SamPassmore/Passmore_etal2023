## pair Global Jukebox and GeLaTo

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(assertthat)
})

set.seed(2897)

#### Read in Data ####
cantometrics_data = read.csv('processed_data/cleaned_cantometrics.csv', na.strings = "") 

# Gelato Data
gelato = read_xlsx('data/GelatoData_PerpopRED_Febr2022.xlsx')
# Only sample one society per Glottocode
gelato = gelato %>% 
  group_by(glottocodeBase) %>%
  top_n(1, samplesize) %>% # take the biggest individual population
  sample_n(1) # sample one at random if there is no difference

x = assert_that(all(table(gelato$glottocodeBase) == 1))

# Read in manually created matching file
id_matching = read_xlsx('data/id_matches.xlsx', na = c("NA"))

## Pair GJB with matching file
paired_df = left_join(cantometrics_data,
                      id_matching,
                      by = c("society_id" = "society_id",
                             "song_id" = "song_id"))

# Pair Matching file with Gelato
paired_df = left_join(paired_df, gelato,
                      by = c("pairing.glottocode" = "glottocodeBase",
                             "PopName" = "PopName"))

# Test: All songs occur only once
x = assert_that(all(table(paired_df$song_id) == 1))

n_societies = n_distinct(paired_df$society_id)
nsoc_songs = nrow(paired_df[!is.na(paired_df$society_id),])
n_genetics = n_distinct(paired_df$PopName)
ngen_songs = nrow(paired_df[!is.na(paired_df$PopName),])
n_linguistic = n_distinct(paired_df$phylogeny.glottocode)
nlin_songs = nrow(paired_df[!is.na(paired_df$phylogeny.glottocode),])

cat("CANTOMETRICS PAIRING:
    There are ", n_societies, "GJB societies with ", nsoc_songs, " songs
    There are ", n_genetics, " genetic pairs with", ngen_songs, " songs
    There are ", n_linguistic, "linguistic pairs with", 
    nlin_songs, "songs \n")

write.csv(paired_df, 
          'processed_data/paired_data.csv', 
          row.names = FALSE)

