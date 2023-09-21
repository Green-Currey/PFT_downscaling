global.grid <- function(num_grids = 100, globe= c(-180, 180, -90, 90)) {
    require(terra)
    # Cell dimensions
    grid.size <- num_grids/10
    grids <- list()
    cell.id <- integer(0)
    
    # Initialize cell counter
    cnt <- 1
    
    dx <- (globe[2] - globe[1]) / grid.size
    dy <- (globe[4] - globe[3]) / grid.size * -1
    # Loop through rows and columns to create lines
    for (row in seq(from=globe[4], by=dy, length.out=grid.size)) {
        for (col in seq(from=globe[1], by=dx, length.out=grid.size)) {
            x <- c(col, col + dx, col + dx, col, col)
            y <- c(row, row, row + dy, row + dy, row)
            grids <- c(grids, list(matrix(c(x, y), ncol=2)))
            cell.id <- c(cell.id, cnt)
            cnt <- cnt + 1
        }
    }
    
    # Create SpatVector of type lines
    cell.grid <- vect(grids, type="polygon", crs = 'EPSG:4326')
    
    # Add attributes to SpatVector
    cell.grid$cell <- cell.id
    return(cell.grid)
}

paint.by.pft <- function(match.lat, match.lon, modis.pft, lpj.pft, grass.pft, lat, lpj, lut, wl.dim = 211, na.val = -9999, to.int = 10000) {
    
    # modis.pft <- modis.pft.index
    # match.lat <- match.lat.lpj
    # match.lon <- match.lon.lpj
    # lpj.pft <- lpj.pft.index
    # grass.pft <- grass.index
    # lat <- latitude
    # lpj <- lpj.array
    # lut <- lut.array

    pft <- paste0('PFT', modis.pft)
    lpj.i <- 0
    switch(pft,
           # 1 = evergreen needleleaf
           PFT1 = {
               if (lpj.pft == 6 || lpj.pft == 3) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- 1
               } else {
                   if (lat > 40) {
                       out <- lut[6,,]*to.int
                   } else {
                       out <- lut[3,,]*to.int
                   }
               }
           },
           
           # 2 - evergreen broadleaf
           PFT2 = {
               if(lpj.pft == 1 || lpj.pft == 4) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   if (lat > 14 || lat < -19) {
                       out <- lut[4,,]*to.int
                   } else {
                       out <- lut[1,,]*to.int
                   }
               }
           },
           
           # 3 - deciduous needleleaf
           PFT3 = {
               if(lpj.pft == 8) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   out <- lut[8,,]*to.int
               }
           },
           
           # 4 - deciduous broadleaf
           PFT4 = {
               if (lpj.pft == 2 || lpj.pft == 5) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   if(lat > 28) {
                       out <- lut[5,,]*to.int
                   } else {
                       out <- lut[2,,]*to.int
                   }
               }
           },
           
           # 5 - shrub
           PFT5 = {
               if (lpj.pft == 9) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   out <- lut[9,,]*to.int
               }
           },
           
           # 6 - grass
           PFT6 = {
               if (lpj.pft == 9 || lpj.pft == 10) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   out <- c3c4.switch(grass.pft, lat, lut)
               }
           },
           
           # 7 - cereal crop
           PFT7 = {
               if (lpj.pft == 9 || lpj.pft == 10) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   out <- c3c4.switch(grass.pft, lat, lut)
               }
           },
           
           # 8 - broadleaf crop
           PFT8 = {
               if (lpj.pft == 9 || lpj.pft == 10) {
                   out <- lpj[match.lat,match.lon,,]*to.int
                   lpj.i <- lpj.i+1
               } else {
                   out <- c3c4.switch(grass.pft, lat, lut)
               }
           },
           
           # Urban - should be removed
           PFT9 = { out <- matrix(na.val, nrow =211, ncol = 12) },
           
           # 10 - snow
           PFT10 = { out <- lut[12,,]*to.int },
           
           # 11 - barren
           PFT11 = { out <- lut[11,,]*to.int }
    ) # end switch
    return( list(spectra = out, count = lpj.i) )
} # end function

c3c4.switch <- function(c3c4.val, lat, lut, na.val = -9999, wl.dim = 211, time.dim = 12, to.int = 10000) {
    if (is.na(c3c4.val)) {c3c4.val <- 3}
    switch(as.integer(c3c4.val),
           { out <- lut[9,,]*to.int },
           { out <- lut[10,,]*to.int },
           { if (lat > 30 || lat < -26) {
                   out <- lut[9,,]*to.int
               } else {
                   out <- lut[10,,]*to.int
               }
           }
    )
    return(out)
}

round.to.lpj <- function(x) {
    if (x == 90 || x == 180) { x <- x-0.1 } 
    if (x == -90 || x == -180 ) { x <- x+0.1 }
    sign_x <- sign(x)
    int_part <- ifelse(sign_x==1, floor(x), ceiling(x))
    dec_part <- abs(x - int_part)
    
    # Determine which of 0.25 or 0.75 is closest to the decimal part
    # If exactly at 0.5, round towards the higher absolute value (0.75)
    if (dec_part == 0.5) {
        closest_value <- 0.75
    } else {
        closest_value <- ifelse(abs(dec_part - 0.25) <= abs(dec_part - 0.75), 0.25, 0.75)
    }
    
    rounded_value <- int_part + closest_value * sign_x
    
    return(rounded_value)
}

max.FPC <- function(fpc.nc) {
    
    # fpc.nc <- "~/Current Projects/SBG/LPJ/PFT_downscaling/data/LPJ_maxfpc_v2.0_fpc.nc"
    
    nc <- nc_open(fpc.nc) 
    fpc <- nc %>% ncvar_get('fpc')
    lon <- nc %>% ncvar_get('lon')
    lat <- nc %>% ncvar_get('lat')
    
    fpc <- fpc[,,,dim(fpc)[4]]

    max_fpc <- array(-9999, dim = c(dim(fpc)[1], dim(fpc)[2]))
    for (i in lon) {
        for (j in lat) {
            x <- match(i,lon) 
            y <- match(j,lat)
            cell <- fpc[x,y, ][-1]
            if (sum(is.na(cell)) == 10 || sum(cell) == 0) {
                max_fpc[x,y] <- NA
            } else {
                max_fpc[x,y] <- which(cell %in% max(cell))
            }
        }
    }
    
    return(max_fpc)
    
}

# Old ---------------------------------------------------------------------
# 
# coord.array <- function(x, extent) {
#     require(terra)
#     
#     # Coordinate map (needed for lat lookup)
#     lats <- rep(seq(extent[4],extent[3], length.out = dim(x)[1]), each = dim(x)[2])
#     lons <- rep(seq(extent[1],extent[2], length.out = dim(x)[2]), each = dim(x)[1])
#     # lats <-  crds(r, na.rm = F)[,2]
#     
#     ca <- array(dim = c(dim(x)[1], dim(x)[2], 2))
#     for (yy in seq(dim(x)[1])) {
#         ca[yy,,1] <- lats[((yy-1)*dim(x)[2]+1):(yy*dim(x)[2])]
#     }
#     for (xx in seq(dim(x)[2])) {
#         ca[,xx,2] <- lons[((xx-1)*dim(x)[1]+1):(xx*dim(x)[1])]
#     }
#     return(ca)
# }
# 
# match.latlon <- function(raster1, ext2) {
#     raster1 <- MODIS.lc5
#     ext2 <- cell.ext
#     require(terra)
#     require(dplyr)
#     ex1 <- raster1 %>% ext()
#     ex2 <- raster1 %>% crop(ext2) %>% ext()
#     
#     # Given NetCDF dimensions
#     # lon.start <- ex1[1]  # Starting longitude in the NetCDF file
#     # lat.start <- ex1[4]    # Starting latitude in the NetCDF file
#     res <- res(raster1)[1]
#     
#     
#     # Calculate the start index
#     start.lon <- round((ex2[1] - ex1[1]) / res+1)
#     start.lat <- round((ex1[4] - ex2[4]) / res+1)
#     
#     # # Print the result
#     # print(paste("Start index for longitude:", start.lon))
#     # print(paste("Start index for latitude:", start.lat))
#     
#     return(c(start.lat, start.lon) %>% as.integer())
#     
# }

# pft.switch <- function(modis.pft, lpj.pft, lpj.r, lat, lut, spec, month, wl.dim = 211) {
#     
#     pft <- paste0('PFT', modis.pft)
#     switch(pft, 
#            # 1 = evergreen needleleaf
#            PFT1 = {
#                if (lpj.pft == 6 || lpj.pft == 3) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    if (lat > 40) {
#                        out <- as.integer(unlist(lut[lut$PFT==6, month]))
#                    } else {
#                        out <- as.integer(unlist(lut[lut$PFT==3, month]))
#                    }
#                }
#            }, 
#            
#            # 2 - evergreen broadleaf
#            PFT2 = {
#                if(lpj.pft == 1 || lpj.pft == 4) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    if (lat > 14 || lat < -19) {
#                        out <- as.integer(unlist(lut[lut$PFT==4, month]))
#                    } else {
#                        out <- as.integer(unlist(lut[lut$PFT==1, month]))
#                    }
#                }
#            },
#            
#            # 3 - deciduous needleleaf
#            PFT3 = { 
#                if(lpj.pft == 8) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    out <- as.integer(unlist(lut[lut$PFT==8, month])) 
#                }
#            },
#            
#            # 4 - deciduous broadleaf
#            PFT4 = {
#                if (lpj.pft == 2 || lpj.pft == 5) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    if(lat > 28) {
#                        out <- as.integer(unlist(lut[lut$PFT==5, month]))
#                    } else {
#                        out <- as.integer(unlist(lut[lut$PFT==2, month]))
#                    }
#                }
#            },
#            
#            # 5 - shrub
#            PFT5 = {
#                if (lpj.pft == 9) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    out <- as.integer(unlist(lut[lut$PFT==9, month])) 
#                }
#            },
#            
#            # 6 - grass
#            PFT6 = { 
#                if (lpj.pft == 9 || lpj.pft == 10) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    out <- c3c4.switch(grass, month, na.val = na.val, wl.dim = wl.dim)
#                }
#            },
#            
#            # 7 - cereal crop
#            PFT7 = { 
#                if (lpj.pft == 9 || lpj.pft == 10) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    out <- c3c4.switch(grass, month, na.val = na.val, wl.dim = wl.dim)
#                }
#            },
#            
#            # 8 - broadleaf crop
#            PFT8 = { 
#                if (lpj.pft == 9 || lpj.pft == 10) {
#                    out <- terra::extract(lpj.r, latlon, ID = F, raw = T)[1,]*10000 %>% as.integer()
#                } else {
#                    out <- c3c4.switch(grass, month, na.val = na.val, wl.dim = wl.dim)
#                }
#            },
#            
#            # 10 - snow
#            PFT10 = { out <- spec$snow.spec },
#            
#            # 11 - barren
#            PFT11 = { out <- spec$soil.spec }
#            
#     ) # end switch
#     return(out)
# } # end function
