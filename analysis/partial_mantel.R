# mantel test

suppressPackageStartupMessages({
  library(readxl)
  library(stringr)
  library(vegan)
  library(optparse)
})


#### Functions #### 

mantel_outputtable = function(..., explanatory, constraint){
  obj = list(...)
  
  if(length(explanatory) != length(obj))
    stop("Name and objects must be the same length")
  
  if(length(constraint) != length(obj))
    stop("Name and objects must be the same length")
  
  stats = lapply(obj, function(x) c(x$statistic,
                                    x$signif)
  )
  stats_table = do.call(rbind, stats)
  stats_table = round(stats_table, 2)
  stats_table = cbind(explanatory, constraint, stats_table)
  colnames(stats_table) = c("explanatory", "constraint", 
                            "Statistic", "P-value")
  data.frame(stats_table)
}

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
region = opt$response

#### Read in distance data from Genalex ####
sheets = excel_sheets(path = datafile)
sheets = sheets[str_detect(string = sheets, pattern = " R$", negate = TRUE)]

distance_matrices = lapply(sheets,
                           function(s)
                             suppressMessages(read_xlsx(datafile, sheet = s, skip = 2)))
names(distance_matrices) = sheets

# save as nexus files
map2(distance_matrices, sheets, function(d, s){
  d2 = d[,1:(ncol(d)-1)]
  d3 = as.matrix(sapply(d2, as.numeric))  
  rownames(d3) = unlist(d[,ncol(d)])
  d4 = as.dist(d3)
  write.nexus.dist(d4, paste0("tmp/", s, ".nex"))
})

#### Reformat from Genalex format ####
distance_matrices = 
  lapply(distance_matrices, function(d){
  rnames = unlist(d[,ncol(d)])
  d = d[,-ncol(d)]
  d = as.matrix(sapply(d, as.numeric))
  rownames(d) = rnames
  d
})

# standardize
distance_matrices = lapply(distance_matrices, function(d){
  d / max(d)
})

#### Calculate partial mantels ####
output = list()
for(i in seq_along(distance_matrices)){
  md = distance_matrices[[i]]
  
  m_gs = mantel.partial(ydis = md, 
                        xdis = distance_matrices$GeneticDist,
                        zdis = distance_matrices$GeographicDist)
  
  m_gt = mantel.partial(ydis = md, 
                        xdis = distance_matrices$GeneticDist,
                        zdis = distance_matrices$LanguageDist)
  
  m_ts = mantel.partial(ydis = md, 
                        xdis = distance_matrices$LanguageDist,
                        zdis = distance_matrices$GeographicDist)
  
  m_tg = mantel.partial(ydis = md, 
                        xdis = distance_matrices$LanguageDist,
                        zdis = distance_matrices$GeneticDist)
  
  m_sg = mantel.partial(ydis = md, 
                        xdis = distance_matrices$GeographicDist,
                        zdis = distance_matrices$GeneticDist)
  
  m_st = mantel.partial(ydis = md, 
                        xdis = distance_matrices$GeographicDist,
                        zdis = distance_matrices$LanguageDist)
  
  output_table = mantel_outputtable(m_gs, m_gt, m_ts, m_tg, m_sg, m_st,
                     explanatory = c("Genes",
                                     "Genes",
                                     "Language",
                                     "Language",
                                     "Spatial",
                                     "Spatial"),
                     constraint = c("Spatial",
                                    "Language",
                                    "Spatial",
                                    "Genes", 
                                    "Genes",
                                    "Language"))
  output_table$input = names(distance_matrices)[i]
  
  output[[i]] = output_table
  
}

output = do.call(rbind, output)

write.csv(output,
          file = paste0(
            "results/mantel/", 
            tools::file_path_sans_ext(basename(datafile)), 
            "_",
            region, 
            "_",
            "partialmantel.csv"), 
          row.names = FALSE)
