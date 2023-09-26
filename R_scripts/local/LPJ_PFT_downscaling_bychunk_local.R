# Load the ncdf4 package
source('~/R/clean.R')
library(ncdf4)
library(terra)
library(tidyverse)
library(readr)
library(rworldmap)
source('~/Current Projects/SBG/LPJ/PFT_downscaling/scripts/paintByPFT.R')

# paths -------------------------------------------------------------------
lpj.path <- file.path('~/Current Projects/SBG/LPJ/Reflectance_Data/version2/')
dp <- '~/Current Projects/SBG/LPJ/PFT_downscaling/data/'


# parameters --------------------------------------------------------------
wl <- seq(400,2500,10)
na_val <- -9999
COMPRESS_LEVEL <- 5

# Data --------------------------------------------------------------------

lpj.array <- nc_open(file.path(lpj.path, 'lpj-prosail_levelC_DR_Version021_m_2020.nc')) %>%
    ncvar_get('DR') %>%
    aperm(c(2,1,3,4))



# The important raster ----------------------------------------------------
pft.nc <- nc_open(file.path(dp,'MODIS_PFT_Type_5_13.nc'))
pft.var <- ncvar_get(pft.nc, 'PFT')



# Other data --------------------------------------------------------------
c3c4.raster <- rast(file.path(dp, 'Osborne_C3C4_raster_1km.tif'))
lpj.fpc.array <- max.FPC(list.files(dp, pattern = '*_fpc.nc', full.names = T)) %>% aperm(c(2,1))       # function that extracts max FPC from FPC output.
lut.array <- nc_open(file.path(dp, 'LPJ_monthly_PFT_reflectance_LUT.nc')) %>% ncvar_get('LUT')
lpj.lons <- seq(-179.75, 179.75, 0.5)
lpj.lats <- seq(89.75, -89.75, -0.5)



# Create NCDF ---------------------------------------------------------------
# Create dimensions
lons <- ncvar_get(pft.nc, 'lon')
lats <- ncvar_get(pft.nc, 'lat')
lon_dim <- ncdim_def("lon", "degrees_east", lons, longname = 'Longitude')
lat_dim <- ncdim_def("lat", "degrees_north", lats, longname = 'Latitude')
time_dim <- ncdim_def("time", units = paste0("Months since ", "2020-01-01"), vals = seq(12), longname = 'Month', calendar = "standard")
wl_dim <- ncdim_def("wl", paste0("nanometers"), wl, longname = 'Wavelength')


# Define a variable
varInput <- "reflectance_resv_"
varname_nc <- "DR"
varUnit <- "unitless"
varLongName <- 'Top-of-Canopy Directional Reflectance'
nc_var <- ncvar_def(varname_nc, varUnit, 
                    list(lon_dim, lat_dim, wl_dim, time_dim), na_val, #x,y,wl,t
                    longname = varLongName,
                    compression = COMPRESS_LEVEL,
                    prec = 'short',
                    shuffle = T,
                    chunksize = NA)

nc_name <- paste0(dp, 'test2.nc')
nc_out <- nc_create(nc_name, nc_var)
print('NC created.')



# define grid and chunk size ----------------------------------------------

# num_grids <- 100
# grid <- global.grid(num_grids)

# Define chunk size
chunk_size <- 500


# Loop through chunks. ---------------------------------------------------------
# Loop through rows/lats/dim1 first, then cols/lons/dim2
t.start <- Sys.time()
print("Beginning downscaling procedure.")
counter <- 0 # start a counter to see how many cells match with LPJ

lon_chunks <- seq(1, dim(pft.var)[1], by = chunk_size)
lat_chunks <- seq(1, dim(pft.var)[2], by = chunk_size)

# Outter-chunk: 
# rows/lats/dim2 first, then cols/lons/dim1
for (cs in lon_chunks) {
    # Define column/lon range for each chunk
    ce <- min(cs + chunk_size - 1, dim(pft.var)[1])
    
    for (rs in lat_chunks) {
        # Define row/lat range for each chunk
        re <- min(rs + chunk_size - 1, dim(pft.var)[2])
        
        # Extract chunk
        chunk <- pft.var[cs:ce, rs:re]
        
        t <- Sys.time()
        # skip if entire cell is NA's
        if ( sum(chunk==0) < ncell(chunk) ) {
            
            out_array <- array(na_val, dim = c(chunk_size, chunk_size, wl_dim$len, time_dim$len))
            
            # Inner-chunk: 
            # looping through cols/lons/dim2 first, then rows/lats/dim1
            # Switches to prevent recalculating latitude
            for( yy in seq(chunk_size) ) {                                   # yy = row index of chunk on chunk scale
                rowy <- rs+yy-1                                                 # rowy = index of chunk on input scale
                match.lat.lpj <- which(round.to.lpj(lats[rowy])==lpj.lats)      # match.lat.lpj = index of chunk on lpj scale
                latitude <- lats[rowy]
                
                for( xx in seq(chunk_size) ) {                               # xx = col index of chunk on chunk scale
                    colx <- cs+xx-1                                             # colx = index of chunk on input scale
                    match.lon.lpj <- which(round.to.lpj(lons[colx])==lpj.lons)  # match.lon.lpj = index of chunk on lpj scale
                    
                    modis.pft.index <- chunk[xx, yy]
                    if (modis.pft.index != 0 ) {
                        
                        grass.index <- c3c4.raster[rowy, colx]
                        lpj.pft.index <- lpj.fpc.array[match.lat.lpj, match.lon.lpj]
                        
                        # Occasional mismatches between lpj and modis PFT raster output NA value for lpj. 
                        # Search for most recent non-NA value
                        if(is.na(lpj.fpc.array[match.lat.lpj, match.lon.lpj])){
                            lpj.pft.index <- lpj.fpc.array[match.lat.lpj, match.lon.lpj-1]
                            if(is.na(lpj.fpc.array[match.lat.lpj, match.lon.lpj])){
                                lpj.pft.index <- lpj.fpc.array[match.lat.lpj-1, match.lon.lpj]
                                if(is.na(lpj.fpc.array[match.lat.lpj, match.lon.lpj])){
                                    lpj.pft.index <- 0
                                }
                            }
                        }
                        
                        PBP <- paint.by.pft(match.lat = match.lat.lpj, match.lon = match.lon.lpj, 
                                            modis.pft = modis.pft.index, lpj.pft = lpj.pft.index, grass.pft = grass.index, 
                                            lat = latitude, lpj = lpj.array, lut = lut.array)
                        out_array[xx,yy,,] <- PBP$spectra
                        counter <- counter + PBP$count
                        
                        # out_array[1:dim(out_array)[1],1:dim(out_array)[2],,] <- chunk
                        
                    } # ...end chunk NA skip
                } # ...end xx loop
            } # ...end yy loop
            
            #first: rows/dim1/lats; second cols/dim2/lons; third..
            start = c(cs, rs, 1, 1)
            count = c(chunk_size, chunk_size, wl_dim$len, time_dim$len) 
            
            ncvar_put(nc_out, nc_var, out_array, start, count)
            
            print(paste0("Processed chunk: [", cs, ", ", rs, "] to [", ce, ", ", re, "]"))
            print(Sys.time()-t)
            
        } # ...end grid na skip
        
        print(paste0("Skipped chunk: [", cs, ", ", rs, "] to [", ce, ", ", re, "]"))
    } # ...end row/lat loop
} # ...end col/lon loop

ncatt_put(nc_out, nc_var, 'scale_factor', 0.0001)

# Close the NetCDF file
nc_close(nc_out)

print("NetCDF successfully file created.")
print('Total time:')
Sys.time()-t.start

print("Percent of spectra directly extracted from LPJ: ")
print(counter/sum(pft.var>1, na.rm = T)*100)


# testing output ----------------------------------------------------------

test <- nc_open(nc_name); test;
test <- test %>% ncvar_get('DR', start=c(1,1,30,7), count = c(4000,2000, 1, 1)); dim(test)
test <- plot(t(rast(test)))
plot(test$lyr.35, main = '740 nm')
plotRGB(test, r = which(wl==660), g = which(wl==510), b = which(wl==450), stretch = 'lin')
