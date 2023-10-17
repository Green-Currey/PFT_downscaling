# Load the ncdf4 package
source('~/R/clean.R')
library(terra)



# paths -------------------------------------------------------------------
dp <- '~/Current Projects/SBG/LPJ/PFT_downscaling/data/'


# processing --------------------------------------------------------------
# Made with "Landcover" script in GEE
modis <- rast(file.path(dp,'MODIS_PFT_Type_5.tif'))
# Water to NA
modis[modis == 0] <- NA
# create ideal dimensions
r <- rast(nrow=20000, ncol=40000)
# resample
modis2 <- resample(modis, r, 'near')
# export
writeRaster(modis2, file.path(dp, 'MODIS_PFT_Type_5_crop.tif'), overwrite = T)
