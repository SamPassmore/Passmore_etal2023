# RDA summary
library(stringr)

files = list.files("results/rda/", full.names = TRUE, pattern = "*.csv")

data = lapply(files, read.csv)
names(data) = files %>% 
  basename() %>% 
  tools::file_path_sans_ext()

twoway = data[str_detect(names(data), "2way")]
threeway = data[str_detect(names(data), "3way")]

t1 = cor.test(twoway[[1]]$adj.r2, twoway[[2]]$adj.r2)
t2 = cor.test(twoway[[1]]$adj.r2, twoway[[3]]$adj.r2)
t3 = cor.test(twoway[[2]]$adj.r2, twoway[[3]]$adj.r2)

t4 = cor.test(threeway[[1]]$adj.r2, threeway[[2]]$adj.r2)
t5 = cor.test(threeway[[1]]$adj.r2, threeway[[3]]$adj.r2)
t6 = cor.test(threeway[[2]]$adj.r2, threeway[[3]]$adj.r2)


comparison_1 = c("2song", "2song", "10song", "2song", "2song", "10song")
comparison_2 = c("10song", "SCCS", "SCCS", "10song", "SCCS", "SCCS")
test = rep(c("2-way", "3-way"), each = 3)
correlation = round(c(t1$estimate, t2$estimate, t3$estimate, t4$estimate, t5$estimate, t6$estimate), 2)

out_table = cbind(test, comparison_1, comparison_2, correlation)
colnames(out_table) = c("RDA type", "Dataset 1", "Dataset 2", "Correlation")

write.csv(out_table, "results/rda/summary_table.csv")
