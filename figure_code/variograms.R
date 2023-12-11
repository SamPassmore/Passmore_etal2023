# make variograms from Genalex plots

suppressPackageStartupMessages({
  library(readxl)
  library(dplyr)
  library(stringr)
  library(ggplot2)
  library(optparse)
  library(scales)
})


#### terminal commands ####
option_list <- list (
  make_option(c("-d", "--datafile"),
              help="Data to use", 
              default = "data/latent_variablemodelcantometrics_2songsdistances.xlsx")
)

parser = OptionParser(option_list=option_list)
arguments = parse_args (parser, positional_arguments=TRUE)
opt = arguments$options

datafile = opt$datafile

all_sheets = excel_sheets(datafile)
result_sheets = all_sheets[str_detect(all_sheets, "R$")]

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

sheets = lapply(result_sheets, function(r){
  name = gsub( " .*$", "", r)
  extract_data(r, name = name)
}) %>% 
  bind_rows()
colnames(sheets) = c("Distance", "r", "U", "L", "Mean.Bootstrap.r", "Ur", "Lr", "type")

sheets$significant = ifelse(
  sheets$Mean.Bootstrap.r <= sheets$U & 
    sheets$Mean.Bootstrap.r >= sheets$L, "not significant", "significant"
)


#### Plots ####
# Main figure
df = sheets %>% 
  filter(type %in% c("Language", "Genetic", "Musical"))

lw = 1.1
p1 = ggplot(df, aes(x = Distance, y = r, group = type, col = type)) + 
  geom_line(linewidth = lw) + 
  geom_errorbar(aes(ymin = Lr, ymax = Ur), width = 200, linewidth = lw) + 
  geom_point(aes(fill = significant, shape = type), size = 4) + 
  geom_line(aes(y = U), linetype = "dashed") + 
  geom_line(aes(y = L), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype="dashed") + 
  theme_classic(base_size = 18) + 
  theme(legend.position=c(.9,.75), legend.title = element_blank()) +
  xlab("Distance (km)") + 
  ylab("Autocorrelation coefficient (r)") + 
  scale_fill_manual(values = c("black", "white"), guide = "none") + 
  scale_x_continuous(label = comma) + 
  scale_shape_manual(values = c(21:23)) + 
  scale_color_manual(values=c("#E41A1C", "#377EB8", "#4DAF4A"))

label = tools::file_path_sans_ext(basename(datafile)) 

ggsave(filename = paste0(
  "figures/figure3_", label, ".png"), 
  plot = p1, width = 210, height = 180, units = "mm")

### Supplementary Figures ####
df2 = sheets %>% 
  filter(!type %in% c("Language", "Genetic", "Musical"))

p2 = ggplot(df2, aes(x = Distance, y = r, group = type, col = type)) + 
  geom_line() + 
  geom_errorbar(aes(ymin = Lr, ymax = Ur), width = 200) + 
  geom_point(aes(fill = significant), shape = 21, size = 2) + 
  geom_line(aes(y = U), linetype = "dashed") + 
  geom_line(aes(y = L), linetype = "dashed") +
  geom_hline(yintercept = 0, linetype="dashed") + 
  theme_classic() + 
  theme(legend.position=c(.9,.2), legend.title = element_blank()) +
  xlab("Distance (km)") + 
  ylab("Autocorrelation coefficient (r)") + 
  scale_fill_manual(values = c("black", "white"), guide = "none") + 
  scale_x_continuous(label = comma) + 
  facet_wrap(~type, nrow = 2)

ggsave(filename = paste0(
  "figures/supplementary_autocorrelation_", label, ".png"), plot = p2)
