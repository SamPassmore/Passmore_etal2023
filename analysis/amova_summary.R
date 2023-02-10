# summarise AMOVA
library(stringr)
library(scales)
library(ggplot2)

#### Functions ####
percent <- function(x, digits = 2, format = "f", ...) {
  paste0(formatC(100 * x, format = format, digits = digits, ...), "%")
}


#### Read in Data ####
files = list.files('results/amova/', "*.csv", full.names = TRUE)
files = files[!str_detect(files, "summary_table.csv")]

labels = files %>% 
  basename() %>%
  tools::file_path_sans_ext() %>% 
  str_split("_") %>% 
  as.data.frame() %>%
  t()

data = lapply(files, read.csv)

#### Combine into a big table ####
out_table = list()
for(i in seq_along(data)){
  nmes = labels[i,]
  d = data[[i]]
  d$sample = nmes[length(nmes)]
  d$grouping = nmes[2]
  out_table[[i]] = d  
}

out_table = do.call(rbind, out_table)
out_table$X. = out_table$X./ 100
out_table$percent = percent(out_table$X.)
out_table$Sigma = round(out_table$Sigma, 3)
out_table$sample = factor(out_table$sample, levels = c("2songs", "10songs", "sccs"))
colnames(out_table) = c("Parameter", "Sigma", "value", "Response", "Sample", "Macrogrouping", "Percent")
out_table = out_table[order(out_table$Sample),]

write.csv(out_table[,c(1:2, 4:7)], "results/amova/summary_table.csv")

# format for graph
colnames(out_table) = make.names(colnames(out_table))
out_table = out_table[out_table$Parameter != "Total variations",]


p1 = ggplot(out_table, aes(y = value, x = Sample, col = Response)) +
  geom_point() + 
  geom_line(aes(group = Response)) + 
  facet_wrap(~Parameter + Macrogrouping)


ggsave(filename = "figures/amova_comparison.png", plot = p1)
