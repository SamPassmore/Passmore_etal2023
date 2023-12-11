
# Global Jukebox Data Source
GJB_REPO=https://github.com/theglobaljukebox/cantometrics
GJB=./raw/gjb

# Always checkout the same commit
$(GJB):
	git submodule add $(GJB_REPO) ./raw/gjb
	cd ./raw/gjb/ && git checkout 930ea435330c0f5141321357904952e7182a489a

#### Recipies ####

help:
	@echo Run these commands in this order to reproduce the results. 
	@echo 1. run `make install` to install necessary R packages and download up-to-date data.
	@echo 2. run `make process_data` to clean an organise the downloaded data for analysis, and create data subsets
	@echo 3. run `make musical_dimensions` to extract latent variables from the latent variable model and reliability restricted model, for all data subsets
	@echo 4. run `make amova` to calculate the proportion of within- and between-group variance for each data subset and each latent variable. 
	@echo 5. run `make phist` to calculate musical similarity between societies, using PhiST scores. This creates phist for the two song dataset only. To calculate for the 10 and sccs samples used `make phist_10` and `make phist_sccs`.
	@echo 6. run `make genalex_1` to prepare data for GenaLex. Models of geographic autocorrelation are performed used GenaLex, an excel plugin, available here: https://biology-assets.anu.edu.au/GenAlEx/Welcome.html
	@echo 7. Manually reproduce the GenaLex results in Excel. 
	@echo 7=8. run `make genalex_2` to make the graphs from the manually created output. 
	@echo 9. run `make delta`, `make delta_10`, and `make delta_sccs` to calculate delta scores for an Indo-European, Oceanic, and African sample. 
	@echo 10. run `make mantel` to calculate the mantel test results between each musical dimension and linguistic, geographic, and genetic distances.
	@echo 11. run `make rda` to calculate the rda results between each musical dimension and linguistic, geographic, and genetic distances
	@echo 12. run `make regional` to calculate the rda results for regional subsets of data.

clean:
	rm -r processed_data results figures

# Install downloads the necessary data from Github to run the models
install: $(GJB)
	Rscript install.R
	
process_data: install
	@echo Clean data and create sensitivity subsets
	mkdir -p processed_data/
	RScript processing/clean_data.R
	RScript processing/pair_data.R
	RScript processing/subset_data.R
	@echo Prune the global phylogeny
	RScript processing/prune_edgetree.R
	@echo Make maps of the samples
	mkdir -p figures/
	RScript figure_code/map_data.R -d processed_data/cantometrics_2songs.csv
	RScript figure_code/map_data.R -d processed_data/cantometrics_10songs.csv
	RScript figure_code/map_data.R -d processed_data/cantometrics_sccs.csv
	
musical_dimensions:
	mkdir -p results/
	@echo Extracting key dimensions of musical diversity...
	@echo Latent variable model:
	cat data/latent_variablemodel.txt
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_2songs.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_10songs.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_sccs.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_2songs.csv -l data/latent_variablemodel_highreliability.txt
	RScript analysis/latentmodel_comparison.R

amova:
	mkdir -p results/amova
	@echo Perfoming Linguistic AMOVA tests with a two song sample...
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r differentiation -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r ornamentation -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r rhythm -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r dynamics -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r tension -g Language_family
	@echo Perfoming Spatial AMOVA tests with a two song sample...
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r differentiation -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r ornamentation -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r rhythm -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r dynamics -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r tension -g Division
	@echo Perfoming Linguistic AMOVA tests with a ten song sample...
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r differentiation -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r ornamentation -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r rhythm -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r dynamics -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r tension -g Language_family
	@echo Perfoming Spatial AMOVA tests with a ten song sample...
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r differentiation -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r ornamentation -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r rhythm -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r dynamics -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r tension -g Division
	@echo Perfoming Linguistic AMOVA tests with the sccs sample...
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r differentiation -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r ornamentation -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r rhythm -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r dynamics -g Language_family
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r tension -g Language_family
	@echo Perfoming Spatial AMOVA tests with the sccs sample...
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r differentiation -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r ornamentation -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r rhythm -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r dynamics -g Division
	Rscript analysis/amova.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r tension -g Division
	
phist:
	@echo	Creation of the Musical PhiST matrices. 
	@echo This will take approximately 6 hours to run, using a Apple M1 Pro processor with 16GB ram.
	mkdir -p results/phist
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r differentiation
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r ornamentation
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r rhythm
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r dynamics
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r tension
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_2songs.csv -r all
	
phist_10:
	mkdir -p results/phist
	@echo This will take approximately 1 hour 20 mins to run, using a Apple M1 Pro processor with 16GB ram.
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r differentiation
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r ornamentation
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r rhythm
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r dynamics
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r tension
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_10songs.csv -r all

phist_sccs:
	mkdir -p results/phist
	@echo This will take approximately 10 minutes to run, using a Apple M1 Pro processor with 16GB ram.
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r differentiation
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r ornamentation
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r rhythm
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r dynamics
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r tension
	RScript analysis/phi_st.R -d processed_data/latent_variablemodelcantometrics_sccs.csv -r all

genalex_1:
	RScript processing/fst_tomatrix.R
	RScript processing/genalex_prep.R -d processed_data/latent_variablemodelcantometrics_2songs.csv
	RScript processing/genalex_prep.R -d processed_data/latent_variablemodelcantometrics_10songs.csv
	RScript processing/genalex_prep.R -d processed_data/latent_variablemodelcantometrics_sccs.csv
	@echo Once these files are created, run the genalex functions using the click and point menus. 
	@echo Running this twice should not overwrite the existing results. Only overwriting the existing distance matrices. 
	@echo For Genalex to run, you need to add two empty rows to the top of each matrix. 

genalex_2:
	@echo Make Genalex Plots
	RScript figure_code/variograms.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx
	RScript figure_code/variograms.R -d data/latent_variablemodelcantometrics_10songsdistances.xlsx
	RScript figure_code/variograms.R -d data/latent_variablemodelcantometrics_sccsdistances.xlsx
	RScript analysis/genalex_comparison.R
	
delta:
	@echo Calculate Delta scores
	#RScript analysis/delta_scores.R -r differentiation -d processed_data/latent_variablemodelcantometrics_2songs.csv
	#RScript analysis/delta_scores.R -r ornamentation -d processed_data/latent_variablemodelcantometrics_2songs.csv
	#RScript analysis/delta_scores.R -r rhythm -d processed_data/latent_variablemodelcantometrics_2songs.csv
	#RScript analysis/delta_scores.R -r dynamics -d processed_data/latent_variablemodelcantometrics_2songs.csv
	#RScript analysis/delta_scores.R -r tension -d processed_data/latent_variablemodelcantometrics_2songs.csv
	RScript analysis/delta_scores.R -r all -d processed_data/latent_variablemodelcantometrics_2songs.csv # you might run out of memory for this analysis. consider using less comparisons or fewer nodes. 
	RScript analysis/deltascore_summary.R -d 2songs
	
delta_10:
	@echo Calculate Delta scores
	RScript analysis/delta_scores.R -r differentiation -d processed_data/latent_variablemodelcantometrics_10songs.csv
	RScript analysis/delta_scores.R -r ornamentation -d processed_data/latent_variablemodelcantometrics_10songs.csv
	RScript analysis/delta_scores.R -r rhythm -d processed_data/latent_variablemodelcantometrics_10songs.csv
	RScript analysis/delta_scores.R -r dynamics -d processed_data/latent_variablemodelcantometrics_10songs.csv
	RScript analysis/delta_scores.R -r tension -d processed_data/latent_variablemodelcantometrics_10songs.csv
	RScript analysis/deltascore_summary.R -d 10songs
	
delta_sccs:
	@echo Calculate Delta scores
	RScript analysis/delta_scores.R -r differentiation -d processed_data/latent_variablemodelcantometrics_sccs.csv
	RScript analysis/delta_scores.R -r ornamentation -d processed_data/latent_variablemodelcantometrics_sccs.csv
	RScript analysis/delta_scores.R -r rhythm -d processed_data/latent_variablemodelcantometrics_sccs.csv
	RScript analysis/delta_scores.R -r dynamics -d processed_data/latent_variablemodelcantometrics_sccs.csv
	RScript analysis/delta_scores.R -r tension -d processed_data/latent_variablemodelcantometrics_sccs.csv
	RScript analysis/deltascore_summary.R -d sccs
	
mantel:
	@echo Calculate Partial Mantel scores
	mkdir -p results/mantel
	RScript analysis/partial_mantel.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx
	RScript analysis/partial_mantel.R -d data/latent_variablemodelcantometrics_10songsdistances.xlsx
	RScript analysis/partial_mantel.R -d data/latent_variablemodelcantometrics_sccsdistances.xlsx
	RScript analysis/summarise_mantel.R

rda:
	@echo Calculate RDA R2
	mkdir -p results/rda
	Rscript analysis/partial_rda.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx
	Rscript analysis/partial_rda.R -d data/latent_variablemodelcantometrics_10songsdistances.xlsx
	Rscript analysis/partial_rda.R -d data/latent_variablemodelcantometrics_sccsdistances.xlsx
	RScript analysis/summarise_rda.R
	RScript analysis/concatenate_rdamantel.R
	
regional:
	@echo Calculate RDA R2
	mkdir -p results/rda
	mkdir -p results/mantel
	Rscript analysis/partial_rda.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx -r Africa
	Rscript analysis/partial_rda.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx -r Europe
	Rscript analysis/partial_rda.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx -r "Southeast Asia"
	Rscript analysis/partial_mantel.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx -r Africa
	Rscript analysis/partial_mantel.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx -r Europe
	Rscript analysis/partial_mantel.R -d data/latent_variablemodelcantometrics_2songsdistances.xlsx -r "Southeast Asia"
	RScript analysis/concatenate_rdamantel.R -r
	
random_test:
	@echo Create three random datasets
	RScript processing/clean_data.R -r 100
	RScript processing/clean_data.R -r 101
	RScript processing/clean_data.R -r 102
	RScript analysis/latent_variablemodel.R -d processed_data/cleaned_cantometrics_100.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cleaned_cantometrics_101.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cleaned_cantometrics_102.csv
