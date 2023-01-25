# Install necessary R Packages

processFile <- function(filepath) {
  con = file(filepath, "r")
  while ( TRUE ) {
    line = readLines(con, n = 1)
    if ( length(line) == 0 ) {
      break
    }
    if(line %in% installed.packages()[,"Package"]){
      break
    }
    install.packages(line, repos="https://cran.rstudio.com")
  }
  
  close(con)
}

processFile('./requirements.txt')