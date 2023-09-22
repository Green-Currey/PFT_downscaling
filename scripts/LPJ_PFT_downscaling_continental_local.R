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


pft.raster <- rast(file.path(dp,'MODIS_PFT_Type_5_clean_crop.tif'))
# 
# r_global <- rast(nrows=20000, ncols=40000,
#                  ext(-180,180,-90,90),
#                  crs=crs("+init=epsg:4326"))
# 
# r <- pft.raster %>% resample(r_global, threads = T, method = 'near')
# plot(r)
# writeRaster(r, file.path(dp,'MODIS_PFT_Type_5_clean_crop.tif'), overwrite = T)
# xmin <- xFromCol(pft.raster, 21550)
# xmax <- xFromCol(pft.raster, 22050)
# ymax <- yFromRow(pft.raster, 5400)
# ymin <- yFromRow(pft.raster, 5900)
# e <- ext(xmin, xmax, ymin, ymax)
# pft.raster1 <- pft.raster %>% crop(e, filename = paste0(dp, 'test_',paste0(xmax,'_',ymax),'.tif'), overwrite = T); plot(pft.raster1)


# pft.raster <- rast(file.path(dp,'test_-76.5045_45.0045.tif')) # great lakes
# pft.raster <- rast(file.path(dp,'test_18.8955_41.4045.tif')) # italy
# pft.raster <- rast(file.path(dp, 'test_148.4955_-17.9955.tif')) # austrailia


# Other data --------------------------------------------------------------

c3c4.raster <- rast(file.path(dp, 'Osborne_C3C4_raster_1km.tif'))
lpj.fpc.array <- max.FPC(list.files(dp, pattern = '*_fpc.nc', full.names = T)) %>% aperm(c(2,1))       # function that extracts max FPC from FPC output.
lut.array <- nc_open(file.path(dp, 'LPJ_monthly_PFT_reflectance_LUT.nc')) %>% ncvar_get('LUT')
lpj.lons <- seq(-179.75, 179.75, 0.5)
lpj.lats <- seq(89.75, -89.75, -0.5)


# Continental data --------------------------------------------------------

sPDF <- vect(getMap())
continents <- na.exclude(unique(sPDF$continent)) 
cont.vect <- sPDF["continent"]
sub <- cont.vect[cont.vect$continent=='North America', ] # this could be input from the bash script
pft.raster <- mask(pft.raster, sub)


# Create NCDF --===---------------------------------------------------------

# Create dimensions
lons <- seq(ext(pft.raster)[1], ext(pft.raster)[2], length.out = ncol(pft.raster))
lats <- seq(ext(pft.raster)[4], ext(pft.raster)[3], length.out = nrow(pft.raster))
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

nc_name <- paste0(dp,'NA2.nc')
nc_out <- nc_create(nc_name, nc_var)
print('nc created')



# define grid and chunk size ----------------------------------------------

# num_grids <- 100
# grid <- global.grid(num_grids)

# Define chunk size
chunk_size <- c(800, 800)


# Loop through chunks. ---------------------------------------------------------
# Loop through rows/lats/dim1 first, then cols/lons/dim2
t.start <- Sys.time()
counter <- 0 # start a counter to see how many cells match with LPJ
ga <- as.array(pft.raster) %>% drop

lon_chunks <- seq(1, dim(ga)[2], by = chunk_size[2])
lat_chunks <- seq(1, dim(ga)[1], by = chunk_size[1])

for (cs in lon_chunks) {
    # cs <- 401
    
    for (rs in lat_chunks) {
        # rs <- 201 
        
        # Define the range for each chunk
        re <- min(rs + chunk_size[1] - 1, dim(ga)[1])
        ce <- min(cs + chunk_size[2] - 1, dim(ga)[2])
        
        # Extract chunk
        chunk <- ga[rs:re, cs:ce]
        t <- Sys.time()
        # skip if entire cell is NA's
        
        # if ( sum(is.na(chunk)) < ncell(chunk)-ncell(chunk)*0.01 ) {
        #     
        #     out_array <- array(na_val, dim = c(chunk_size, wl_dim$len, time_dim$len))
        #     
        #     # swtich to looping through cols/lons/dim2 first, then rows/lats/dim1
        #     # prevents updating latitude variable every time
        #     
        #     for( yy in seq(chunk_size[1]) ) {                                   # yy = row index of chunk on chunk scale
        #         rowy <- rs+yy-1                                                 # rowy = index of chunk on input scale
        #         match.lat.lpj <- which(round.to.lpj(lats[rowy])==lpj.lats)      # match.lat.lpj = index of chunk on lpj scale
        #         latitude <- lats[rowy]
        #         
        #         for( xx in seq(chunk_size[2]) ) {                               # xx = col index of chunk on chunk scale
        #             colx <- cs+xx-1                                             # colx = index of chunk on input scale
        #             match.lon.lpj <- which(round.to.lpj(lons[colx])==lpj.lons)  # match.lon.lpj = index of chunk on lpj scale
        #             
        #             modis.pft.index <- chunk[yy, xx]
        #             if ( !is.nan(modis.pft.index) ) {
        #                 
        #                 grass.index <- c3c4.raster[rowy, colx]
        #                 lpj.pft.index <- lpj.fpc.array[match.lat.lpj, match.lon.lpj]
        #                 
        #                 # Occasional mismatches between lpj and modis PFT raster output NA value for lpj. 
        #                 # Search for most recent non-NA value
        #                 
        #                 if(is.na(lpj.fpc.array[match.lat.lpj, match.lon.lpj])){
        #                     lpj.pft.index <- lpj.fpc.array[match.lat.lpj, match.lon.lpj-1]
        #                     if(is.na(lpj.fpc.array[match.lat.lpj, match.lon.lpj])){
        #                         lpj.pft.index <- lpj.fpc.array[match.lat.lpj-1, match.lon.lpj]
        #                         if(is.na(lpj.fpc.array[match.lat.lpj, match.lon.lpj])){
        #                             lpj.pft.index <- 0
        #                         }
        #                     }
        #                 }
        #                 
        #                 PBP <- paint.by.pft(match.lat = match.lat.lpj, match.lon = match.lon.lpj, 
        #                                     modis.pft = modis.pft.index, lpj.pft = lpj.pft.index, grass.pft = grass.index, 
        #                                     lat = latitude, lpj = lpj.array, lut = lut.array)
        #                 out_array[yy,xx,,] <- PBP$spectra
        #                 counter <- counter + PBP$count
        #                 
        #                 # out_array[1:dim(out_array)[1],1:dim(out_array)[2],,] <- chunk
        #                 
        #             } # ...end chunk NA skip
        #         } # ...end xx loop
        #     } # ...end yy loop
        #     #first: rows/dim1/lats; second cols/dim2/lons; third..
        #     start = c(rs, cs, 1, 1)
        #     count = c(chunk_size[1], chunk_size[2], wl_dim$len, time_dim$len) 
        #     ncvar_put(nc_out, nc_var, out_array, start, count)
        #     
        #     print(paste0("Processed chunk: [", rs, ", ", cs, "] to [", re, ", ", ce, "]"))
        #     print(Sys.time()-t)
        #     
        # } # ...end grid na skip
        print(paste0("Skipped chunk: [", rs, ", ", cs, "] to [", re, ", ", ce, "]"))
    }
    
}

ncatt_put(nc_out, nc_var, 'scale_factor', 0.0001)

# Close the NetCDF file
nc_close(nc_out)

print("NetCDF file created.")
print('total time:')
Sys.time()-t.start

print("Percent of spectra directly extracted from LPJ: ")
print(counter/sum(ga>1, na.rm = T)*100)

# testing output ----------------------------------------------------------

test <- nc_open(nc_name); test;
test <- test %>% ncvar_get('DR'); dim(test)
test <- rast(test[,,,7])/10000
plot(test$lyr.35, main = '740 nm')
plotRGB(test, r = which(wl==660), g = which(wl==510), b = which(wl==450), stretch = 'lin')
