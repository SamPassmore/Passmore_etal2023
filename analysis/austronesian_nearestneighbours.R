## Austronesian Nearest neighbours

library(dplyr)
library(geosphere)

austronesians = read.csv("https://raw.githubusercontent.com/D-PLACE/dplace-data/master/phylogenies/gray_et_al2009/taxa.csv")
glottolog = read.csv("https://raw.githubusercontent.com/glottolog/glottolog-cldf/master/cldf/languages.csv")

austronesians = left_join(austronesians, glottolog, by = c("glottocode" = "ID"))

# must have long lat data
austronesians = austronesians %>% 
  filter(!is.na(Latitude) & !is.na(Longitude)) %>% 
  distinct(glottocode, Latitude, Longitude) # only allow one language per glottocode

dd = distm(austronesians[,c("Longitude", "Latitude")], fun = distHaversine)
dd = as.matrix(dd)
diag(dd) = NA

min_dist = apply(dd, 1, min, na.rm = TRUE) / 1000 # divide by 1000 to make m to km

plot(density(min_dist), main = "Distribution of nearest neighbour distances in Austronesian societies",
     xlab = "Distance (kms)")
summary(min_dist)
