# Code repository for Independent histories underlie global musical, linguistic, and genetic diversity
_Sam Passmore, Anna L. C. Wood, Chiara Barbieri, Dor Shilton, Hideo Daikoku, Quentin D. Atkinson, Patrick E. Savage_

This repository contains the code and data necessary to reproduce the results for the paper _Independent histories underlie global musical, linguistic, and genetic diversity_.
All result files are held in this repository, and can be reproduced using the Makefile. 
One exception are the autocorrelational results which are calculated through the Excel add-on GenALeX and would need to be manually reproduced. 
If you are using a MacOS or Linux, make should be installed on your machine by default. If you are using a Windows, please ensure you have installed the make proceedure. 

The Makefile contains the following instructions:
```
Run these commands in this order to reproduce the results. 
1. run `make install` to install necessary R packages and download up-to-date data.
2. run `make process_data` to clean an organise the downloaded data for analysis, and create data subsets
3. run `make musical_dimensions` to extract latent variables from the latent variable model and reliability restricted model, for all data subsets
4. run `make amova` to calculate the proportion of within- and between-group variance for each data subset and each latent variable. 
5. run `make phist` to calculate musical similarity between societies, using PhiST scores. This creates phist for the two song dataset only. To calculate for the 10 and sccs samples used `make phist_10` and `make phist_sccs`.
6. run `make genalex_1` to prepare data for GenaLex. Models of geographic autocorrelation are performed used GenaLex, an excel plugin, available here: https://biology-assets.anu.edu.au/GenAlEx/Welcome.html
7. Manually reproduce the GenaLex results in Excel. 
8. run `make genalex_2` to make the graphs from the manually created output. 
9. run `make delta`, `make delta_10`, and `make delta_sccs` to calculate delta scores for an Indo-European, Oceanic, and African sample. 
10. run `make mantel` to calculate the mantel test results between each musical dimension and linguistic, geographic, and genetic distances.
11. run `make rda` to calculate the rda results between each musical dimension and linguistic, geographic, and genetic distances
12. run `make regional` to calculate the rda results for regional subsets of data.
```
## Data Sources

This project combined musical, genetic, and linguistic data sources. Here, we list the original sources of those datasets. 

| Dataset                               | Citation                                                                                                                                                                                                                                                                                                                                                                                                                      | Data Location                                    |
|---------------------------------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|--------------------------------------------------|
| The Global Jukebox: Cantometrics      | Wood, A. L. C., Kirby, K. R., Ember, C. R., Silbert, S., Passmore, S., Daikoku, H., McBride, J., Paulay, F., Flory, M. J., Szinger, J., D’Arcangelo, G., Bradley, K. K., Guarino, M., Atayeva, M., Rifkin, J., Baron, V., Hajli, M. E., Szinger, M., & Savage, P. E. (2022). The Global Jukebox: A public database of performing arts and culture.  PLOS ONE, 17 (11), e0275469. https://doi.org/10.1371/journal.pone.0275469 | https://github.com/theglobaljukebox/cantometrics |
| GeLaTo: Genes and Languages, Together | Barbieri, C., Blasi, D. E., Arango-Isaza, E., Sotiropoulos, A. G., Hammarström, H., Wichmann, S., Greenhill, S. J., Gray, R. D., Forkel, R., Bickel, B., & Shimizu, K. K. (2022). A global analysis of matches and mismatches between human genetic and linguistic histories.  Proceedings of the National Academy of Sciences, 119 (47), e2122084119. https://doi.org/10.1073/pnas.2122084119                                | https://github.com/gelato-org/gelato-data        |
| Global Language Phylogeny             | Bouckaert, R., Redding, D., Sheehan, O., Kyritsis, T., Gray, R., Jones, K. E., & Atkinson, Q. (2022, July 20). Global language diversification is linked to socio-ecology and threat status. https://doi.org/10.31235/osf.io/f8tr6                                                                                                                                                                                            | https://osf.io/yzxv9/                            |


