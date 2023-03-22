# join mantel and rda
library(dplyr)
library(purrr)
library(optparse)

option_list <- list( 
  make_option(c("-r", "--region"),
              help="Region to subset to",
              default = "world")
)

opt = parse_args(OptionParser(option_list=option_list))

region = opt$region

mantel_files = list.files('results/mantel/', pattern = paste0(region, "_partialmantel.csv"), full.names = TRUE)
rda_files = list.files('results/rda/', pattern = paste0(region, "_3wayRDA.csv"), full.names = TRUE)

mantel = lapply(mantel_files, read.csv)
names(mantel) = basename(mantel_files)
rda = lapply(rda_files, read.csv)
names(rda) = basename(rda_files)

# Change names in mantel
mantel = lapply(mantel, function(m){
  m$explanatory = recode(m$explanatory, Genes = "GeneticDist", Language = "LanguageDist", Spatial = "GeographicDist")
  m$constraint = recode(m$constraint, Genes = "GeneticDist", Language = "LanguageDist", Spatial = "GeographicDist")
  m
})

# join mantel and rda
out_table = map2(mantel, rda, function(m, r){
  dd = left_join(m, r, by = c("explanatory", "constraint", "input" = "response"))
  dd = dd[!is.na(dd$r2),c("input", "explanatory", "constraint", "Statistic", "P.value", "r2", "adj.r2", 
                          "perm_adjr2z", "perm_adjr2z_p")]
  dd$perm_adjr2z_p = dd$perm_adjr2z_p / 100
  dd = mutate(.data = dd, across(where(is.numeric), round, 3))
  dd
})

write.csv(out_table[[1]], file = "results/rda/rda_mantelsummary_10songs.csv", row.names = FALSE)
write.csv(out_table[[2]], file = "results/rda/rda_mantelsummary_2songs.csv", row.names = FALSE)
write.csv(out_table[[3]], file = "results/rda/rda_mantelsummary_sccs.csv", row.names = FALSE)
