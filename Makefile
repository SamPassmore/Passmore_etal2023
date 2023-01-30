
# Global Jukebox Data Source
GJB_REPO=https://github.com/theglobaljukebox/cantometrics
GJB=./raw/gjb

# Always checkout the same commit
$(GJB):
	git submodule add $(GJB_REPO) ./raw/gjb
	cd ./raw/gjb/ && git checkout 930ea435330c0f5141321357904952e7182a489a

#### Recipies ####

clean:
	rm -r processed_data

# Install downloads the necessary data from Github to run the models
install: $(GJB) $(DPLACE)
	Rscript install.R
	
process_data: install
	@echo Clean data and create sensitivity subsets
	mkdir -p processed_data/
	RScript processing/clean_data.R
	RScript processing/pair_data.R
	RScript processing/subset_data.R
	@echo Make maps of the samples
	mkdir -p figures/
	RScript figure_code/map_data.R -d processed_data/cantometrics_2songs.csv
	RScript figure_code/map_data.R -d processed_data/cantometrics_10songs.csv
	RScript figure_code/map_data.R -d processed_data/cantometrics_sccs.csv
	RScript figure_code/map_data.R -d processed_data/cantometrics_regular.csv
	
musical_dimensions:
	mkdir -p results/
	@echo Extracting key dimensions of musical diversity...
	@echo Latent variable model:
	cat data/latent_variablemodel.txt
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_2songs.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_10songs.csv
	RScript analysis/latent_variablemodel.R -d processed_data/cantometrics_sccs.csv
	
	