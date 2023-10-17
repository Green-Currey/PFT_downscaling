source('~/R/clean.R')
library(tidyverse)
library(readr)

# Instead of repeating the same spectra 12 times for eahc month, need to obtain specta for each month from EMIT or something.

dp <- '~/Current Projects/SBG/LPJ/PFT_downscaling/data/'

snow <- read_csv(file.path(dp,'snow_spectra.csv'))
snow.a <- approx(x = snow$wl, y=snow$spn0.1, xout = seq(400,2500,10),method = 'linear', rule =2)

sand <- read_csv(file.path(dp,'sand_spectra.csv'))
sand.a <- approx(x = sand$wl, y=sand$reflectance, xout = seq(400,2500,10),method = 'linear', rule =2)

urban <- read_csv(file.path(dp,'urban_spectra.csv'))
urban.a <- approx(x = urban$wl, y=urban$reflectance, xout = seq(0.4,2.5,.01), method = 'linear', rule =2)

snow <- matrix(rep(snow.a$y, times = 12), ncol = 12, byrow = F) %>% data.frame()
sand <- matrix(rep(sand.a$y, times = 12), ncol = 12, byrow = F) %>% data.frame()
urban <- matrix(rep(urban.a$y, times = 12), ncol = 12, byrow = F) %>% data.frame()

write_csv(snow, file.path(dp, 'snow_matrix.csv'))
write_csv(sand, file.path(dp, 'sand_matrix.csv'))
write_csv(urban, file.path(dp, 'urban_matrix.csv'))
