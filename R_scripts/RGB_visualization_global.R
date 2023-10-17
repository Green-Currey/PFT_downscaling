# Load the ncdf4 package
source('~/R/clean.R')
library(terra)
library(tidyverse)
library(tidyterra)
library(rworldmap)


dp <- '~/Current Projects/SBG/LPJ/PFT_downscaling/data/'
rfl <- rast(file.path(dp, 'lpj-prosail_levelC_DR_RGB_1km_7_2020.tif'))
rfl[rfl==0] <- NA

global.shp <- vect(getMap())

# Plot the RGB image
ggplot() +
    geom_spatraster_rgb(data = rfl, r=3, g=2, b=1,max_col_value = 3000) +
    geom_spatvector(data = global.shp, fill = 'transparent') +
    scale_fill_manual(na.value = 'transparent') +
    theme_classic(base_size = 20) +
    labs(title = 'LPJ-PROSAIL 1km Simulated Reflectances (Chunk = 13)')
