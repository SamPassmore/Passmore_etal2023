# Extracting musical dimensions from the latent variable model

#!/usr/bin/env Rscript

### script that takes a text file as input containing a lavaan model
### 
### Fits the model
### 
### Outputs the latent variables and fit statistics

suppressPackageStartupMessages({
  library(readr)
  library(lavaan)
  library(optparse)
  library(dplyr)
})

option_list <- list( 
  make_option(c("-d", "--datafile"), action="store", 
              type="character", 
              default = 'processed_data/cantometrics_2songs.csv', 
              help="Data file to use")
)

opt = parse_args(OptionParser(option_list=option_list))

datafile = opt$datafile

#### Read in Data ####
lavaan_model = read_file(file = "data/latent_variablemodel.txt")
cantometrics = read.csv(datafile)

#### Run LAVAAN Model ####
# Fit lavaan model
fit = lavaan(model = lavaan_model,
             data  = cantometrics, 
             auto.var=TRUE, 
             auto.fix.first=TRUE,
             auto.cov.lv.x=TRUE)

cat(paste0("RMSEA should be < 0.08 \nRMSEA:", 
             round(fitMeasures(fit, "rmsea"), 2),
             "\n90% CI:",
             round(fitMeasures(fit, "rmsea.ci.lower"), 3),
             ", ",
             round(fitMeasures(fit, "rmsea.ci.upper"), 3),
           "\n"
  )) # should be < 0.08

cat(paste0("SRMR should be <0.08 \n SRMR: ", round(
  fitMeasures(fit, "srmr"), 2),
  "\n"
  )) # should be < 0.08

cat(paste0("CFI should be >0.95 \n CFI: ", round(fitMeasures(fit, "cfi"), 2),
           "\n")) # should be > 0.95

cat("Top 5 possible improvements:\n")
print(modindices(fit, sort = TRUE, maximum.number = 12))

param_est = parameterestimates(fit, standardized = TRUE)

write.csv(param_est, 
          paste0(
            'results/lavaanparameterestimates_', 
            basename(datafile))
          )

# Get latent variables
latent_variables = lavPredict(fit)

latent_data = cbind(cantometrics, latent_variables)

write.csv(latent_data, 
          paste0('processed_data/latentvariables_', 
                 basename(datafile)), 
          row.names = FALSE,
          fileEncoding = 'utf-8')

cat("CANTOMETRICS SAMPLE:\nThere are", nrow(latent_data), "songs and", length(unique(latent_data$society_id)), "societies used in this analysis.\n")

