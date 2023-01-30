# map of the dataset

## This script builds a map figure
suppressPackageStartupMessages({
  library(ggplot2)
  library(optparse)
  library(dplyr)
  # library(tidyr)
  # library(GGally)
  # library(rgl)
  # library(scales)
})

option_list <- list( 
  make_option(c("-d", "--datafile"), action="store", 
              type="character", 
              default = 'processed_data/cantometrics_2songs.csv', 
              help="Data file to use")
)

opt = parse_args(OptionParser(option_list=option_list))

datafile = opt$datafile

data = read.csv(datafile)


map_df = data %>% 
  group_by(society_id) %>% 
  summarise(
    society_id = first(society_id),
    n_songs = n(),
    Society_latitude = first(Society_latitude), 
    Society_longitude = first(Society_longitude), 
    PopName = first(PopName), 
    phylogeny.glottocode = first(phylogeny.glottocode)
    )

## Adjust Longitude for Pacific centering
map_df$plot_longitude = ifelse(
  map_df$Society_longitude <= -25, 
  map_df$Society_longitude + 360,
  map_df$Society_longitude)

## Add colours for societies included in Genetic / Linguistic analyses
map_df$gen_ling = ifelse(!is.na(map_df$PopName) & !is.na(map_df$phylogeny.glottocode), "Included", "Excldued")

world <- 
  ggplot2::map_data('world2', 
                    wrap=c(-25,335), # rewrapping the worldmap, Pacific center. 
                    ylim=c(-55,90)) # cutting out antarctica (not obligatory) and the northermost part where there are no language points in glottolog

basemap <- ggplot() +
  geom_polygon(data=world, aes(x=long, #plotting the landmasses
                               y=lat,group=group),
               colour="gray90",
               fill="gray90", size = 0.5) +
  theme(#all of theme options are set such that it makes the most minimal plot, no legend, not grid lines etc
    panel.grid.major = element_blank(), 
    panel.grid.minor = element_blank(),
    axis.title.x=element_blank(),
    axis.title.y=element_blank(),
    axis.line = element_blank(),
    panel.border = element_blank(),
    panel.background = element_rect(fill = "white"),
    axis.text.x = element_blank(),
    axis.text.y = element_blank(),
    axis.ticks = element_blank(),
    axis.ticks.length = unit(0, "mm"))   +
  coord_map(projection = "vandergrinten") + #a non-rectangular world map projection that is a decen compromise between area and distances accuracy
  ylim(-55,90) #cutting out antarctica (not obligatory) 

gen_ling = map_df %>% 
  dplyr::filter(gen_ling == "Included")

society_map = basemap + 
  geom_point(data = map_df,
             aes(x=plot_longitude, 
                 y = Society_latitude,
                 size = n_songs), 
             shape = 19, 
             alpha = 0.6, 
             stroke = 0.4,
             col = "grey") +
  geom_point(data = gen_ling,
             aes(x=plot_longitude, 
                 y = Society_latitude,
                 size = n_songs),
             col = "#D9484E",
             shape = 19, 
             alpha = 0.6, 
             stroke = 0.4,
             bg = "black") + 
  scale_size_continuous(range = c(1, 5)) + 
  scale_color_manual(values=c("grey", "red")) + 
  theme(legend.position = "none", text = element_text(size=20))

ggsave(paste0(
  "figures/",
  tools::file_path_sans_ext(basename(datafile)),
  "_map.png"),
  society_map
)
