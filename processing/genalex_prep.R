# nexus.dist to csv

suppressPackageStartupMessages({
  library(phangorn)
  library(geosphere)
  library(optparse)
  library(dplyr)
  library(readxl)
  library(xlsx)
  library(assertthat)
})

## Command line options

#### terminal commands ####
option_list <- list (
  make_option(c("-d", "--datafile"),
              help="Data to use", 
              default = "processed_data/latent_variablemodelcantometrics_2songs.csv")
)

parser = OptionParser(option_list=option_list)
arguments = parse_args (parser, positional_arguments=TRUE)
opt = arguments$options

datafile = opt$datafile

# Check this should be run
label = tools::file_path_sans_ext(basename(datafile))   
file = paste0("data/", label, "distances.xlsx") # this is saved to data because we will produce manual analyses using this file

if(file.exists(file)){
  cat("The genalex file already exists.\n")
} else {
  
  #### Read in the data ####
  cantometrics_societies = read.csv('raw/gjb/cldf/societies.csv')
  cantometric_sample = read.csv(datafile)
  cantometric_ids = read_xlsx('data/id_matches.xlsx', sheet = "id_matches", na = "NA")
  language = read.nexus("processed_data/pruned_edgetree.tree")
  
  # make sure the phylogeny glottocode match is included
  cantometrics_societies = left_join(cantometrics_societies,
                                     distinct(cantometric_ids[,c("society_id", "phylogeny.glottocode")]), 
                                     by = c("society_id"))
  
  #### Read in Genetic distance ####
  genetics_matrix = read.csv('results/phist/fst_matrix.csv', row.names = 1)
  colnames(genetics_matrix) = rownames(genetics_matrix)
  
  #### Read in Musical distances ####
  files = list.files('results/phist/', pattern = "*2songs.nex", full.names = TRUE)
  
  music_dists = lapply(files, function(f){
    dd = readDist(f, format = "nexus")
    as.matrix(dd)
  })
  names(music_dists) = c("all", "differentiation", "dynamics", "ornamentation", "rhythm", "tension")
  
  # identify what societies have music and geographic distance
  matched_societies = cantometrics_societies %>%
    filter(!is.na(Society_latitude) & !is.na(Society_latitude)) %>% # Have a geographic location
    filter(society_id %in% rownames(genetics_matrix)) %>% # Is paired to genetic data
    filter(society_id %in% rownames(music_dists[[1]])) %>% # We have musical data
    filter(!is.na(phylogeny.glottocode) & phylogeny.glottocode %in% language$tip.label) %>%  # We have language pairings
    filter(society_id %in% unique(cantometric_sample$society_id)) %>% # and is in the data sample
    dplyr::select(society_id, Glottocode = phylogeny.glottocode, Society_longitude, Society_latitude) %>% 
    distinct(Glottocode, .keep_all = TRUE)
  matched_societies$society_id = as.character(matched_societies$society_id)
  
  #### Subset music data ####
  music_dists = lapply(music_dists, function(md){
    md = md[matched_societies$society_id, matched_societies$society_id]
    cbind(md, rownames(md))
  })
  
  # check all societies are in the dataset
  x = assert_that(all(unlist(lapply(music_dists, function(x)
    all(rownames(x) %in% matched_societies$society_id)))))
  # All matrices have the same number of rows as matched societies
  x = assert_that(all(sapply(music_dists, nrow) == nrow(matched_societies)))
  
  #### Make Geographic matrix ####
  geo_dist = distm(
    matched_societies[,c("Society_longitude", "Society_latitude")], 
    fun = distHaversine
  ) 
  geo_dist = geo_dist / max(geo_dist)
  dimnames(geo_dist) = list(matched_societies$society_id,
                            matched_societies$society_id)
  geo_dist = cbind(geo_dist, rownames(geo_dist))
  
  # check all societies are in the dataset
  x = assert_that(all(all(rownames(geo_dist) %in% matched_societies$society_id)))
  # All matrices have the same number of rows as matched societies
  x = assert_that(nrow(geo_dist) == nrow(matched_societies))
  
  ##### Subset genetic data #####
  genetics_matrix = genetics_matrix[matched_societies$society_id,matched_societies$society_id]
  genetics_matrix = cbind(genetics_matrix, rownames(genetics_matrix))
  
  # check all societies are in the dataset
  x = assert_that(all(all(rownames(genetics_matrix) %in% matched_societies$society_id)))
  # All matrices have the same number of rows as matched societies
  x = assert_that(nrow(genetics_matrix) == nrow(matched_societies))
  
  ##### build linguistic distance ####
  language = keep.tip(language, matched_societies$Glottocode)
  tree_dist = cophenetic.phylo(language)
  tree_dist = tree_dist / max(tree_dist)
  
  colnames(tree_dist) = matched_societies$society_id[
    match(colnames(tree_dist), matched_societies$Glottocode)]
  rownames(tree_dist) = colnames(tree_dist)
  
  tree_dist = tree_dist[rownames(geo_dist),rownames(geo_dist)]
  tree_dist = cbind(tree_dist, rownames(tree_dist))
  
  # check all societies are in the dataset
  x = assert_that(all(all(rownames(tree_dist) %in% matched_societies$society_id)))
  # All matrices have the same number of rows as matched societies
  x = assert_that(nrow(tree_dist) == nrow(matched_societies))
  
  ## Check all matrices match
  x = assert_that(all(dim(tree_dist) == dim(geo_dist)))
  x = assert_that(all(rownames(tree_dist) == rownames(geo_dist)))
  
  x = assert_that(all(dim(tree_dist) == dim(genetics_matrix)))
  x = assert_that(all(rownames(tree_dist) == rownames(genetics_matrix)))
  
  x = assert_that(all(dim(tree_dist) == dim(genetics_matrix)))
  x = assert_that(all(rownames(tree_dist) == rownames(genetics_matrix)))
  
  x = assert_that(all(unlist(lapply(music_dists, function(m)
    all(rownames(m) %in% rownames(genetics_matrix))))))
  
  
  #### Write output ####
  write.xlsx(geo_dist, file, sheetName = "GeographicDist", append = TRUE, row.names = FALSE) 
  write.xlsx(tree_dist, file, sheetName = "LanguageDist", append = TRUE, row.names = FALSE)
  write.xlsx(genetics_matrix, file, sheetName = "GeneticDist", append = TRUE, row.names = FALSE)
  write.xlsx(as.matrix(music_dists$all), file, sheetName = "MusicalDist", append = TRUE, row.names = FALSE) 
  write.xlsx(as.matrix(music_dists$differentiation), file, sheetName = "DifferentiationDist", append = TRUE, row.names = FALSE)
  write.xlsx(as.matrix(music_dists$dynamics), file, sheetName = "DynamicsDist", append = TRUE, row.names = FALSE)
  write.xlsx(as.matrix(music_dists$ornamentation), file, sheetName = "OrnamentationDist", append = TRUE, row.names = FALSE)
  write.xlsx(as.matrix(music_dists$rhythm), file, sheetName = "RhythmDist", append = TRUE, row.names = FALSE)
  write.xlsx(as.matrix(music_dists$tension), file, sheetName = "TensionDist", append = TRUE, row.names = FALSE)
}

