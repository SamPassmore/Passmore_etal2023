# prune edge tree
suppressPackageStartupMessages({
  library(ape)
  library(stringr)
  library(readxl)
  library(assertthat)
  library(dplyr)
})

edge_tree = read.nexus('data/EDGE6635-merged-relabelled.tree')

glottocodes = str_extract(edge_tree$tip.label, "[a-z]{4}[0-9]{4}")

# did I fail to find any glottocodes?
x = assert_that(!any(is.na(glottocodes)))
# are all glottocodes unique?
x = assert_that(length(glottocodes) == length(unique(glottocodes)))

# replace tip labels with glottocodes
edge_tree$tip.label = glottocodes

cantometrics_societies = read_xlsx('data/id_matches.xlsx', na = "NA") %>% 
  group_by(phylogeny.glottocode) %>% 
  summarise(society_id = first(society_id), 
            Glottocode = first(phylogeny.glottocode))

matched_glottocodes = cantometrics_societies$Glottocode[
  cantometrics_societies$Glottocode %in% glottocodes
]

pruned_edgetree = keep.tip(edge_tree, matched_glottocodes)

write.nexus(pruned_edgetree, file = "processed_data/pruned_edgetree.tree")
