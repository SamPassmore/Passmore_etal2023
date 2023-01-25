
# Global Jukebox Data Source
GJB_REPO=https://github.com/theglobaljukebox/cantometrics
GJB=./raw/gjb

# Always checkout the same commit
$(GJB):
	git submodule add $(GJB_REPO) ./raw/gjb
	cd ./raw/gjb/ && git checkout 930ea435330c0f5141321357904952e7182a489a

#### Recipies ####

# Install downloads the necessary data from Github to run the models
install: $(GJB) $(DPLACE)
	Rscript processing/install.R
	
process_data: install
	@echo Clean data and create sensitivity subsets
	mkdir -p processed_data/
	RScript processing/cantometrics_preperation.R 