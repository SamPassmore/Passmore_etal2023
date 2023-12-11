library(dplyr)

original_data = read.csv('processed_data/latent_variablemodelcantometrics_2songs.csv')
latent_vars = c("differentiation", "ornamentation", "rhythm", "dynamics", "tension")
output = list()
for(i in 1:100){
  value = sample.int(100, 1)
  system(paste0("RScript processing/clean_data.R -r ", value))
  
  new_file = paste0("processed_data/cleaned_cantometrics_", value, ".csv")
  new_data = read.csv(new_file)
  new_data = new_data[new_data$song_id %in% original_data$song_id,]
  write.csv(new_data, new_file)
  system(paste0("RScript analysis/latent_variablemodel.R -d ", new_file))
  new_latent = read.csv(
    paste0("processed_data/latent_variablemodelcleaned_cantometrics_", value, ".csv")
  )
  cor_list = purrr::map2(original_data[,latent_vars], new_latent[,latent_vars], cor) %>% 
    unlist()
  output[[i]] = data.frame(names = names(cor_list), values = cor_list)
  
  ## remove the created file
  file.remove(new_file)
}

outout = bind_rows(output)
tapply(outout$values, outout$names, summary)
