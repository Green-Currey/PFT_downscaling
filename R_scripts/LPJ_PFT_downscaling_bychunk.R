# Load the ncdf4 package
library(ncdf4)
library(terra)
library(tidyverse)
library(readr)
source(file.path(Sys.getenv("scriptspath"), 'paintByPFT.R'))


t.start <- Sys.time()
print("Beginning downscaling procedure.")

# paths -------------------------------------------------------------------
lpjpath <- Sys.getenv("lpjpath")
inpath <- Sys.getenv("inpath")
outpath <- Sys.getenv("outpath")
outname <- Sys.getenv("outname")
refl_stream <- Sys.getenv("reflectanceType")

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
                    list(lon_dim, lat_dim, wl_dim, time_dim), na_val, #x,y,wl,t
                    longname = varLongName,
                    compression = COMPRESS_LEVEL,
                    prec = 'short',
                    shuffle = T,
                    chunksize = NA)

nc_name <- paste0(outpath, outname)
nc_out <- nc_create(nc_name, nc_var)
print('NC created.')



# define chunk size ----------------------------------------------
# Define chunk size
chunk_size = as.numeric(Sys.getenv("chunksize"))
# chunk_size <- c(chunksize, chunksize)



# Loop through chunks. ---------------------------------------------------------
# Loop through rows/lats/dim1 first, then cols/lons/dim2
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
            for( yy in seq(chunk_size[1]) ) {                                     # yy = row index of chunk on chunk scale
                rowy <- rs+yy-1                                                 # rowy = index of chunk on input scale
                match.lat.lpj <- which(round.to.lpj(lats[rowy])==lpj.lats)      # match.lat.lpj = index of chunk on lpj scale
                latitude <- lats[rowy]

                for( xx in seq(chunk_size) ) {                               # xx = col index of chunk on chunk scale
                    colx <- cs+xx-1                                             # colx = index of chunk on input scale
                    match.lon.lpj <- which(round.to.lpj(lons[colx])==lpj.lons)  # match.lon.lpj = index of chunk on lpj scale

                    modis.pft.index <- chunk[xx, yy]
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

#Assign global attributes
ncatt_put(nc_out, 0, 'Title', 'LPJ-PROSAIL V003 L2 Global Simulated Dynamic Surface Reflectance')
ncatt_put(nc_out, 0, "Project_Description", '1 km Resolution Simulating Global Dynamic Surface Reflectances base on the MODIS PFT Type 5 Product')
ncatt_put(nc_out, 0, "Spatial_Reference", 'WGS84 - World Geodetic System 1984; EPSG:4326')
ncatt_put(nc_out, 0, 'Spatial_Extent', '-180, 180, -90, 90 (xmin, xmax, ymin, ymax)')
ncatt_put(nc_out, 0, "Spatial_Resolution", '1 km')
ncatt_put(nc_out, 0, 'Time_Start', format(lubridate::ymd_hms(paste0(Year, '-01-01', '00:00:01')), format = "%Y-%m-%dT%H:%M:%OS3Z"))
ncatt_put(nc_out, 0, 'Time_End', format(lubridate::ymd_hms(paste0(Year, '-12-31', '23:59:59')), format = "%Y-%m-%dT%H:%M:%OS3Z"))
ncatt_put(nc_out, 0, "Production_Date_Time", print(date()))
ncatt_put(nc_out, 0, 'Institution', 'National Aeronautics and Space Administration, Goddard Space Flight Center')
ncatt_put(nc_out, 0, "Contact", 'brycecurrey93@gmail.com')
ncatt_put(nc_out, 0, 'Citation', 'Poulter, B., et al. (2023). JGR-Biogeosciences. https://doi.org/10.1029/2022JG006935')
ncatt_put(nc_out, 0, 'More information', 'https://github.com/Green-Currey/PFT_downscaling')
ncatt_put(nc_out, nc_var, 'scale_factor', 0.0001)



# Close the NetCDF file
nc_close(nc_out)

print("NetCDF successfully file created.")
print('Total time:')
print(Sys.time()-t.start)

print("Percent of spectra directly extracted from LPJ: ")
print(counter/sum(pft.var>1, na.rm = T)*100)

