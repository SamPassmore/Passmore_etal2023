# Partial RDA correlation

suppressPackageStartupMessages({
  library(readxl)
  library(stringr)
  library(vegan)
  library(ape)
  library(optparse)
  library(ggplot2)
  library(purrr)
  library(dplyr)
})

#### Parameters ####

option_list <- list( 
  make_option(c("-d", "--datafile"), action="store", 
              type="character", 
              default = "data/latent_variablemodelcantometrics_2songsdistances.xlsx", 
              help="Data file to use"),
  make_option(c("-r", "--region"),
              help="Region to subset to",
              default = "world")
)

opt = parse_args(OptionParser(option_list=option_list))

datafile = opt$datafile
region = opt$region

#### Read in Distance data ####
sheets = excel_sheets(path = datafile)
sheets = sheets[str_detect(string = sheets, pattern = " R$", negate = TRUE)]

distance_matrices = lapply(sheets,
                           function(s)
                             suppressMessages(read_xlsx(datafile, sheet = s, skip = 2)))
names(distance_matrices) = sheets

cantometric_societies = read.csv('raw/gjb/cldf/societies.csv')
if(region != "world"){
  ids = cantometric_societies %>% filter(Region == region) %>% pull(society_id) %>% 
    as.character()
} else {
  ids = unlist(distance_matrices[[1]][,ncol(distance_matrices[[1]])])
}

#### Reformat from Genalex format ####
distance_matrices = 
  lapply(distance_matrices, function(d){
    rnames = unlist(d[,ncol(d)])
    d = d[,-ncol(d)]
    d = as.matrix(sapply(d, as.numeric))
    rownames(d) = rnames
    colnames(d) = str_remove_all(colnames(d), "X")
    ids_s = ids[ids %in% rnames]
    d[ids_s, ids_s]
  })

cat("There are", nrow(distance_matrices[[1]]), "societies in this sample.\n")

# standardize
distance_matrices = lapply(distance_matrices, function(d){
  d / max(d)
})

musical_distances = distance_matrices[4:length(distance_matrices)]

#### RDA Analysis ####
##### Step 1: Get key dimensions #####
music_pcoa = lapply(musical_distances, function(md){
  pcoa(md)
})
genetic_pcoa <- pcoa(distance_matrices$GeneticDist)
spatial_pcoa <- pcoa(distance_matrices$GeographicDist)
language_pcoa <- pcoa(distance_matrices$LanguageDist) 

# get eigenvalues explained variance
pcoa_results = lapply(distance_matrices, function(m){
  
  pcoa_out = pcoa(m)
  
  eigen = pcoa_out$values$Eigenvalues
  orig_sum = sum(eigen)
  eigen[eigen < 0] = 0
  constant = 1 / orig_sum
  eigen_c = eigen * constant
  pcoa_out$values$explained = eigen_c / sum(eigen_c)
  
  pcoa_out
})

# # Rescale the PCoA components in relation to the explained variance.  
# pcoa_results = lapply(pcoa_results, function(x){
#   print("hi")
#   rescale_explainedvariance(x) 
# })

#### Get PCOA Factors ####
pcoa_factors = lapply(pcoa_results, function(p){
  p$vectors[,which(p$values$explained > 0.1)]
})

#### RDA ####
rda_func = function(x, y){
  rda(x, y)
}

rda_pairs = expand.grid(names(pcoa_factors), names(pcoa_factors))
rda_pairs = rda_pairs[rda_pairs[,1] != rda_pairs[,2],]
rda_pairs = rda_pairs[!rda_pairs[,1] %in% c("LanguageDist", "GeneticDist", "GeographicDist"),]

rda_output = apply(rda_pairs, 1, function(x){
  rda(X = pcoa_factors[[x[1]]],
      Y = pcoa_factors[[x[2]]])
})

rda_permuted_output = apply(rda_pairs, 1, function(x){
  perms = list()
  for(i in 1:100){X = pcoa_factors[[x[1]]]
  permutation_order = sample(1:nrow(X))
  X = X[permutation_order,]
  
  
  rda_result = rda(X = X,
                   Y = pcoa_factors[[x[2]]])
  perms[[i]] = RsquareAdj(rda_result)
  }
  
  do.call(rbind, perms)
  
})


summary_list = list()
for(i in 1:nrow(rda_pairs)){
  nmes = unlist(rda_pairs[i,])
  rda_o = rda_output[[i]]
  r2 = unlist(RsquareAdj(rda_o))
  
  perm_out = matrix(as.numeric(rda_permuted_output[[i]]), ncol = 2)
  perm_r2 = colMeans(perm_out)
  
  rda_z = (r2 - perm_out)/apply(perm_out, 2, sd)
  p.value = apply(rda_z, 2, function(x) sum(x > 1))
  
  oo = data.frame(response = nmes[1], 
                  explanatory = nmes[2],
                  r2 = r2[1],
                  adj.r2 = r2[2],
                  perm_r2 = perm_r2[1],
                  perm_adjr2 = perm_r2[2],
                  perm_r2z = rda_z[1],
                  perm_adjr2z = rda_z[2],
                  perm_r2z_p = p.value[1],
                  perm_adjr2z_p = p.value[2])
  summary_list[[i]] = oo
}

summary_out = do.call(rbind, summary_list)

#### Parital RDA 
rda_3pairs = expand.grid(names(pcoa_factors), names(pcoa_factors), names(pcoa_factors))
rda_3pairs = rda_3pairs[rda_3pairs[,1] != rda_3pairs[,2],]
rda_3pairs = rda_3pairs[rda_3pairs[,1] != rda_3pairs[,3],]
rda_3pairs = rda_3pairs[rda_3pairs[,2] != rda_3pairs[,3],]
rda_3pairs = rda_3pairs[rda_3pairs[,2] %in% c("LanguageDist", "GeneticDist", "GeographicDist"),]
rda_3pairs = rda_3pairs[rda_3pairs[,3] %in% c("LanguageDist", "GeneticDist", "GeographicDist"),]
rda_3pairs = rda_3pairs[!rda_3pairs[,1] %in% c("LanguageDist", "GeneticDist", "GeographicDist"),]

rda_3output = apply(rda_3pairs, 1, function(x){
  rda(X = pcoa_factors[[x[1]]],
      Y = pcoa_factors[[x[2]]],
      Z = pcoa_factors[[x[3]]])
})

summary_list3 = list()
for(i in 1:nrow(rda_3pairs)){
  nmes = unlist(rda_3pairs[i,])
  rda_o = rda_3output[[i]]
  r2 = unlist(RsquareAdj(rda_o))
  
  perm_out = matrix(as.numeric(rda_permuted_output[[i]]), ncol = 2)
  perm_r2 = colMeans(perm_out)
  
  rda_z = (r2 - perm_out)/apply(perm_out, 2, sd)
  p.value = apply(rda_z, 2, function(x) sum(x > 1))
  
  oo = data.frame(response = nmes[1], 
                  explanatory = nmes[2],
                  constraint = nmes[3],
                  r2 = r2[1],
                  adj.r2 = r2[2],
                  perm_r2 = perm_r2[1],
                  perm_adjr2 = perm_r2[2],
                  perm_r2z = rda_z[1],
                  perm_adjr2z = rda_z[2],
                  perm_r2z_p = p.value[1],
                  perm_adjr2z_p = p.value[2])
  summary_list3[[i]] = oo
}

summary_out3 = do.call(rbind, summary_list3)


#### Save output ####
label = datafile %>%
  basename() %>% 
  tools::file_path_sans_ext(.) %>% 
  str_split("_") %>% 
  unlist() %>% 
  tail(1)

write.csv(summary_out,
          file = paste0("results/rda/", label, "_", str_remove_all(region, " "), "_2wayRDA.csv"), 
          row.names = FALSE)

write.csv(summary_out3,
          file = paste0("results/rda/", label, "_", str_remove_all(region, " "), "_3wayRDA.csv"),
          row.names = FALSE)
