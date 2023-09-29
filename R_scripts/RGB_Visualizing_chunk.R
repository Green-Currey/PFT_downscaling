# Example displaying one chunk

# Load the ncdf4 package
source('~/R/clean.R')
library(ncdf4)
library(terra)
library(tidyverse)
library(tidyterra)
library(rworldmap)


dp <- '~/Current Projects/SBG/LPJ/PFT_downscaling/'

pft.nc <- nc_open(file.path(dp,'lpj-prosail_levelC_DR_version022_1km_m_2020_13.nc'))
pft.nc
 # start at the first element of each dimension

lon <- ncvar_get(pft.nc, 'lon')
lat <- ncvar_get(pft.nc, 'lat')
wl <- ncvar_get(pft.nc, 'wl')

# Array/Raster parameters
extent <- ext(min(lon), max(lon), min(lat), max(lat))
wgs <- crs('+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs')
count <- c(-1,-1, 1, 1) # specify chunk size (all lons, all lats, 1 bin, 1 month)

# First, select the band # and Month # using the start parameter.
# Next, to convert to raster, we must transpose the array so the dimensions are lat,lon.
# We can then convert to raster and add the spatial metadata
R <- rast(t(ncvar_get(pft.nc, 'DR', start <- c(1, 1, 25, 7), count)), ext = extent, crs = wgs)
G <- rast(t(ncvar_get(pft.nc, 'DR', start <- c(1, 1, 15, 7), count)), ext = extent, crs = wgs)
B <- rast(t(ncvar_get(pft.nc, 'DR', start <- c(1, 1, 7, 7), count)), ext = extent, crs = wgs)

# Assign 0 values to NA
R[R==0] <- NA
G[G==0] <- NA
B[B==0] <- NA
rgb <- c(R,G,B)

# Obtain global spatvector and clip to chunk 13
global.shp <- vect(getMap()) %>% crop(rgb)

# Plot the RGB image
ggplot() +
    geom_spatraster_rgb(data = rgb, max_col_value = 0.35) +
    # geom_spatvector(data = global.shp, fill = 'transparent') +
    scale_fill_manual(na.value = 'transparent') +
    theme_classic(base_size = 20) +
    labs(title = 'LPJ-PROSAIL 1km Simulated Reflectances (Chunk = 13)')
     