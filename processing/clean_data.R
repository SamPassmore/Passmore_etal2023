# This script cleans the Cantometric data for analysis

suppressPackageStartupMessages({
  library(dplyr)
  library(tidyr)
  library(stringr)
  library(assertthat)
  library(readxl)
  library(optparse)
})

source('processing/processing_helper.R')

option_list <- list( 
  make_option(c("-r", "--random"), action="store", 
              type="character", 
              default = FALSE, 
              help="Create a secondary random run of the data")
)

opt = parse_args(OptionParser(option_list=option_list))

random_run = opt$random

#### Read in Data ####
# Raw codes
cantometrics_data = read.csv('raw/gjb/cldf/data.csv', na.strings = "") 
# Society metadata
cantometric_society = read.csv('raw/gjb/cldf/societies.csv')
# Song Metadata
cantometric_songs = read.csv('raw/gjb/cldf/songs.csv')

#### Clean data ####

## Remove double codes from songs
# Explainer: some cantometrics songs are double coded for particular features. 
# For example, if they display different features throughout a song
# However, for analytic purposes we must have on value / line / song
# These codes are selected randomly. 
cantometrics_data$dual_id = paste0(cantometrics_data$song_id, 
                                   cantometrics_data$society_id,
                                   cantometrics_data$var_id)


idx = which(duplicated(cantometrics_data$dual_id))

n_distinct(cantometrics_data$song_id[idx])
cantometrics_check = cantometrics_data %>%
  group_by(dual_id) %>%
  mutate(Diff = code - lag(code))


# Sample data
set.seed(337474)
cantometrics_clean = cantometrics_data %>%
  group_by(dual_id) %>%
  sample_n(1)

# Make sure the right amount of data is there
x = assert_that(all(dim(cantometrics_clean) == c(213419,6)))

# Convert data from long to wide format for next stages
cantometrics_wide = pivot_wider(cantometrics_clean[,c("song_id", "society_id", "var_id", "code")],
                                values_from = "code", 
                                names_from = "var_id")

#### Rescale Cantometric Data ####
variable_metadata = read.csv('./raw/gjb/etc/codes.csv')

cols_cantometrics = colnames(cantometrics_wide[,3:39])
for(i in 1:ncol(cantometrics_wide[,3:39])){
  variable_name = cols_cantometrics[i]
  
  variable = cantometrics_wide[[variable_name]]
  
  var_set = variable_metadata %>%
    dplyr::filter(var_id == variable_name) %>%
    pull(code) %>%
    unique(.)
  
  cantometrics_wide[,variable_name] = musical_conversion(variable, var_set)
}

#### Reverse Musical Scales ####
## Some variables are coded so that low numbers are frequent occurrences. 
## Here, we reverse the scale of those variables so high values are frequent occurrences.

reverse_lines = paste0("line_", c(17, 18, 23, 26, 27, 28:32, 34:37))
cantometrics_wide[,reverse_lines] = 1 - cantometrics_wide[,reverse_lines]

# Random check of correct codes
x = assert_that(all(head(cantometrics_wide$line_17) == c(0.00, 0.25, 1.00, 0.25, 0.00, 0.75)))

## Variables that are changed:
# Line 17: 1 = Very long phrases; 13 =  Very short phrases. (1-2 seconds).
# Line 18: 1 = There are more than eight phrases before a full repeat. 13 = One or two phrases, symmetrically arranged
# Line 23: 1 = Extreme embellishment. 13 = Little or no embellishment.
# Line 26: 1 = Extreme rubato. 13 = No rubato
# Line 27: 1 = Extreme rubato. 13 = No rubato
# Line 28: 1 = Maximal glissando. 13 = Little or no glissando.
# Line 29: 1 = Much melisma. 13 = Little or no melisma.
# Line 30: 1 = Much tremolo. 13 = Little or no tremolo. 
# Line 31: 1 = Much glottal. 13 = Little or no glottal. 
# Line 32: 1 = Very high. 13 = Very low. (Vocal Pitch)
# Line 34: 1 = Extreme nasalization. 13 = Little or no nasalization.
# Line 35: 1 = Extreme rasp. 13 = None. Voices lack rasp.
# Line 36: 1 = Very forceful accent. 13 = Very relaxed, absence of clear stresses.
# Line 37: 1 = Very precise enunciation. 13 =  	Very softened enunciation.

# Test there are 407 missing values (expected). 
x = assert_that(sum(is.na(cantometrics_wide[,3:39])) == 407, msg = "More values are missing than expected!")

# Only keep complete cases
# cantometrics_wide = cantometrics_wide[complete.cases(cantometrics_wide),]

## Add society metadata back
cantometrics = dplyr::left_join(cantometrics_wide, cantometric_society, 
                                by = "society_id")

## Add song metadata back
# first remove data that exists in both datasets
cantometric_songs = cantometric_songs %>% 
  dplyr::select(-c(Region, Division, Subregion, Area))

cantometrics = dplyr::left_join(cantometrics, cantometric_songs, 
                                by = c("song_id", "society_id"))

#### Manual matching changes ####

# Make manual adjustments to glottocodes to ensure links to phylogeny
new_codes = read_xlsx('data/id_matches.xlsx', sheet = "changes")

cantometrics = left_join(cantometrics, 
                         new_codes, 
                         by = c("Glottocode" = "current"))

# replace glottocodes
cantometrics$Glottocode[!is.na(cantometrics$new)] = 
  cantometrics$new[!is.na(cantometrics$new)]

# Only keep societies with a Glottocode match
cantometrics = 
  cantometrics[!is.na(cantometrics$Glottocode) | cantometrics$Glottocode == "",]

# Only keep societies who have complete data (codes for all lines)
# complete_data = !is.na(rowSums(cantometrics[,str_detect(colnames(cantometrics), "line")]))
complete_data = complete.cases(cantometrics[,str_detect(colnames(cantometrics), "line")])

## Only keep songs with complete data
cantometrics = cantometrics[complete_data,]

# Test there are only positive values
x = assert_that(all(cantometrics[,cols_cantometrics] >= 0), msg = "Some values are positive!")

# Test that all values are less than 1. 
x = assert_that(all(cantometrics[,3:39] <= 1, na.rm = TRUE))

x = assert_that(all(table(cantometrics$song_id) == 1), 
                msg = "Some songs are duplicated")

cat("CANTOMETRICS SAMPLE:
There are ", nrow(cantometrics), " songs and ", length(unique(cantometrics$society_id)), " societies")

if(random_run != "FALSE"){
  write.csv(cantometrics, 
            paste0('processed_data/cleaned_cantometrics_', random_run,'.csv'), 
            row.names = FALSE)
} else {
  write.csv(cantometrics, 
            'processed_data/cleaned_cantometrics.csv', 
            row.names = FALSE)
}

