# genalex comparison

library(stringr)
library(readxl)

# functions
extract_data = function(x, name = "Language"){
  df = suppressMessages(
    read_xlsx(datafile, x, skip = 28,col_names = FALSE))
  df = df[c(2:5, 12, 15, 16),1:41]
  
  output = t(df[,2:41])
  colnames(output) = unlist(df[,1])
  output = data.frame(output)
  output$distance = name
  
  output
}

# Get data
files = list.files("data/", 
                   pattern = "latent_variablemodelcantometrics_*",
                   full.names = TRUE)
files = files[!str_detect(files, "\\$")]

sheets = list()
for(i in seq_along(files)){
  datafile = files[i]
  all_sheets = excel_sheets(datafile)
  result_sheets = all_sheets[str_detect(all_sheets, "R$")]
  
  sheets[[i]] = lapply(result_sheets, function(r){
    name = gsub( " .*$", "", r)
    extract_data(r, name = name)
  }) %>% 
    bind_rows()
  colnames(sheets[[i]]) = c("Distance", "r", "U", "L", "Mean.Bootstrap.r", "Ur", "Lr", "type")
}

t1 = cor.test(sheets[[1]]$r, sheets[[2]]$r)
t2 = cor.test(sheets[[1]]$r, sheets[[3]]$r)
t3 = cor.test(sheets[[2]]$r, sheets[[3]]$r)

comparison_1 = c("2Song", "2Song", "10Song")
comparison_2 = c("10Song", "SCCS", "10Song")
correlation = round(c(t1$estimate, t2$estimate, t3$estimate), 3)

out_table = cbind(comparison_1, comparison_2, correlation)
write.csv(out_table, 'results/genalex_comparison.csv')
