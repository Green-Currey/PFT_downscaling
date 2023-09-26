# Load the ncdf4 package
library(ncdf4)
library(terra)
library(tidyverse)
library(readr)
source(file.path(Sys.getenv("scriptspath"), 'paintByPFT.R'))


# paths -------------------------------------------------------------------
lpjpath <- Sys.getenv("lpjpath")
inpath <- Sys.getenv("inpath")
outpath <- Sys.getenv("outpath")
outname <- Sys.getenv("outname")
refl_stream <- Sys.getenv("reflectanceType")
chunk <- Sys.getenv("chunk")

# parameters --------------------------------------------------------------
wl <- seq(400,2500,10)
na_val <- -9999
COMPRESS_LEVEL <- 5
Year <- Sys.getenv("year")
in_version <- Sys.getenv("version")


# LPJ Data --------------------------------------------------------------------
lpj.array <- nc_open(file.path(lpjpath, paste0('lpj-prosail_levelC_',refl_stream,'_',in_version,'_m_',Year,'.nc'))) %>%
    ncvar_get(refl_stream) %>%
    aperm(c(2,1,3,4))



# The important raster ----------------------------------------------------
pft.nc <- nc_open(Sys.getenv('MODIS_NC'))
pft.var <- ncvar_get(pft.nc, 'PFT')

# Other data --------------------------------------------------------------
lpj.fpc.array <- max.FPC(list.files(lpjpath, pattern = '_fpc.nc', full.names = T)) %>% aperm(c(2,1))       # function that extracts max FPC from FPC output.
c3c4.raster <- rast(file.path(inpath, 'Osborne_C3C4_raster_1km.tif'))
lut.array <- nc_open(file.path(inpath, 'LPJ_monthly_PFT_reflectance_LUT.nc')) %>% ncvar_get('LUT')
lpj.lons <- seq(-179.75, 179.75, 0.5)
lpj.lats <- seq(89.75, -89.75, -0.5)

print("Data read in.")


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
                    list(lat_dim, lon_dim, wl_dim, time_dim), na_val, 
                    longname = varLongName,
                    compression = COMPRESS_LEVEL,
                    prec = 'short',
                    shuffle = T,
                    chunksize = NA)

nc_name <- paste0(outpath, outname)
nc_out <- nc_create(nc_name, nc_var)
print('NC created.')




# Loop through chunks. ---------------------------------------------------------
# Loop through rows/lats/dim1 first, then cols/lons/dim2
t.start <- Sys.time()
print("Beginning downscaling procedure.")
counter <- 0 # start a counter to see how many cells match with LPJ

# no internal chunking.
out_array <- array(na_val, dim = c(lon_dim$len, lat_dim$len, wl_dim$len, time_dim$len))
            
for( yy in seq(lat_dim$len) ) {                                     # yy = row index of chunk on chunk scale
    rowy <- rs+yy-1                                                 # rowy = index of chunk on input scale
    match.lat.lpj <- which(round.to.lpj(lats[rowy])==lpj.lats)      # match.lat.lpj = index of chunk on lpj scale
    latitude <- lats[rowy]

    for( xx in seq(lon_dim$len) ) {                               # xx = col index of chunk on chunk scale
        colx <- cs+xx-1                                             # colx = index of chunk on input scale
        match.lon.lpj <- which(round.to.lpj(lons[colx])==lpj.lons)  # match.lon.lpj = index of chunk on lpj scale

        modis.pft.index <- pft.var[xx, yy]
        if ( modis.pft.index!=0 ) {

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

        } # ...end chunk NA skip
    } # ...end xx loop
} # ...end yy loop

ncvar_put(nc_out, nc_var, out_array) 
ncatt_put(nc_out, nc_var, 'scale_factor', 0.0001)

# Close the NetCDF file
nc_close(nc_out)

print(paste0("NetCDF successfully file created for chunk ", chunk))
print('Total time:')
print(Sys.time()-t.start)

print("Percent of spectra directly extracted from LPJ: ")
print(counter/sum(pft.var>1, na.rm = T)*100)

