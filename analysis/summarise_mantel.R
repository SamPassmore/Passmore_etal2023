# RDA summary
library(stringr)

files = list.files("results/mantel/", full.names = TRUE)

data = lapply(files, read.csv)
names(data) = c("10song", "2song", "sccs")

# filter out bad comaprisons
data = lapply(data, function(d){
  d = d[!(d$explanatory == "Language" & d$input == "LanguageDist"),]
  d = d[!(d$constraint == "Language" & d$input == "LanguageDist"),]
  
  d = d[!(d$explanatory == "Spatial" & d$input == "GeographicDist"),]
  d = d[!(d$constraint == "Spatial" & d$input == "GeographicDist"),]
  
  d = d[!(d$explanatory == "Genes" & d$input == "GeneticDist"),]
  d = d[!(d$constraint == "Genes" & d$input == "LanguagGeneticDisteDist"),]
  d
})

t1 = cor.test(data[[1]]$Statistic, data[[2]]$Statistic)
t2 = cor.test(data[[1]]$Statistic, data[[3]]$Statistic)
t3 = cor.test(data[[2]]$Statistic, data[[3]]$Statistic)

comparison_1 = c("2song", "2song", "10song")
comparison_2 = c("10song", "SCCS", "SCCS")
correlation = round(c(t1$estimate, t2$estimate, t3$estimate), 2)

out_table = cbind(comparison_1, comparison_2, correlation)
colnames(out_table) = c("Dataset 1", "Dataset 2", "Correlation")

write.csv(out_table, "results/mantel/summary_table.csv")
