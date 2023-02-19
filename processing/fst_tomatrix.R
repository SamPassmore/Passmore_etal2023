# Organise the Fst matrix for analyses
suppressPackageStartupMessages({
  library(tidyr)
  library(dplyr)
  library(assertthat)
  library(readxl)
})

cantometric_ids = read_xlsx('data/id_matches.xlsx', sheet = "id_matches", na = "NA")

cantometric_ids = cantometric_ids %>% 
  dplyr::select(PopName, pairing.glottocode, society_id) %>%
  group_by(PopName, society_id) %>% 
  mutate(n_songs = n()) %>% 
  ungroup() %>%
  group_by(PopName) %>% 
  slice_max(n_songs) %>% 
  ungroup() %>% 
  distinct()

genetics_long = read.csv('data/PairwiseFstListinfo_Cantometric.txt', sep = "\t")

# pair glottocodes to genetics data
genetics_long = left_join(genetics_long, cantometric_ids, 
                          by = c("Pop1" = "PopName")) %>% 
  left_join(., cantometric_ids, 
            by = c("Pop2" = "PopName"))

genetics_long = genetics_long %>% 
  dplyr::filter(!is.na(pairing.glottocode.x)) %>% 
  dplyr::filter(!is.na(pairing.glottocode.y)) %>% 
  select(Pop1, Pop2, FST)

pop_names = unique(c(genetics_long$Pop1, 
                     genetics_long$Pop2))

# Change populations with FST value of 0 to a very small number
genetics_long[genetics_long$FST == 0, "FST"] = 0.0000000000001

genetics_matrix = matrix(NA, 
                         ncol = length(pop_names), 
                         nrow = length(pop_names), 
                         dimnames = list(pop_names, pop_names))

for(i in 1:nrow(genetics_long)){
  row = genetics_long[i,]
  genetics_matrix[row[,1], row[,2]] = row[,3]
  genetics_matrix[row[,2], row[,1]] = row[,3]
}

# fill in the other triangle of the matrix
genetics_matrix[lower.tri(genetics_matrix)] = 
  t(genetics_matrix)[lower.tri(genetics_matrix)]

# Distance on the diagonal is zero
diag(genetics_matrix) = 0

# check the values went in correctly
x = assert_that(genetics_matrix["Abkhasian", "Armenian"] == 0.00346965,
            msg = "Genetics matrix hasn't been filled properly")
x = assert_that(genetics_matrix["French_Northwest", "Finnish"] == 0.00774858,
            msg = "Genetics matrix hasn't been filled properly")
x = assert_that(any(colnames(genetics_matrix) == "Han_Guangdong"),
            msg = "Data pairing hasn't worked")

# Some Fst measures are slightly below zero. 
# They should theoretically all be above zero so we force that here.
if(any(genetics_matrix < 0)) genetics_matrix[genetics_matrix < 0] = 0.00001


x = assert_that(all(genetics_matrix >= 0))

# Relabel with Society_ids

# ensure we label with the most frequent society id (sometimes we aggregate societies)
cantometric_ids = cantometric_ids %>% 
  group_by(PopName, society_id) %>%
   %>% 
  slice_max(n_songs)
colnames(genetics_matrix) = cantometric_ids$society_id[match(rownames(genetics_matrix), cantometric_ids$PopName)]
rownames(genetics_matrix) = colnames(genetics_matrix)

write.csv(genetics_matrix, 'results/phist/fst_matrix.csv')
