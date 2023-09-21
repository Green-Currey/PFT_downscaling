# PFT_downscaling
## This repository contains the scripts to downscale LPJ-PROSAIL data by mapping LPJ spectra to MODIS MCD12Q1 Type 5 PFT data using a "paint-by-numbers" approach.

### The process to downscale the LPJ data to MODIS Type 5 PFT data is as follows:
1. Divide the globe into chunks that contain small enough chunks to be written into the netcdf format but not so small that it takes too long for the SLURM script to run (the limit is 12 hours).
    1. *NOTE*:optimal size seems to be 500km x 500km.
2. Loop through each 1km2 grid cell and examine the MODIS PFT value.
    1. Check to see if the MODIS PFT value matches the LPJ PFT value.
    2. If a match, extract the spectra for the corresponding LPJ grid cell.
    3. If no match, use LPJ-derived LUT for corresponding spectra.
       1. *Note*: The latitude of the grid cell is taken into account to pick the most representative LPJ PFT spectra. For example, if the MODIS PFT is _Deciduous Broadleaf_, the LUT will check the latitude to obtain spectra from either _Tropical Broadleaf Raingreen_ or _Temperate Broadleaf Summergreen_ from LPJ. If the latitude is greater than 28 degrees North or South, it chooses the temperate PFT spectra from the LUT; otherwise, the tropical PFT spectra.
3. Selected spectra are mapped to the same resolution as the MODIS PFT map (1km)
4. These data are written to the ncdf file.

### Files and scripts relevant to this process:
- _execute_LPJ_downscaling.sh_ -- bash script to execute the Rscript and pass necessary file paths and parameters.
- _LPJ_PFT_downscaling.R_ -- contains the code that does the looping through each grid cell and writing to the ncdf file.
- _paintByPFT.R_ -- contains all the functions called in the LPJ_PFT_downscaling.R proceedure. 

### More information: 
- LPJ-PROSAIL data: [Poulter et al., 2023. Simulating Global Dynamic Surface Reflectances for Imaging Spectroscopy Spaceborne Missions: LPJ-PROSAIL](https://onlinelibrary.wiley.com/doi/abs/10.1029/2022JG006935)
- MODIS data here: [mcd12q1v006](https://lpdaac.usgs.gov/products/mcd12q1v006/)
- Google slide of the procedure here: [Paint-by-pft approach](https://docs.google.com/presentation/d/1Wh_hnF6Rc1M3smSVDY1JST_kC6i_KZisgWF26pYTGco/edit?usp=sharing)
- Converting Osborne et al., 2014 C3/C4 maps to raster [C3/C4 maps to raster (Google slides)](https://docs.google.com/presentation/d/1uqTXW6YhO1ElM9dWfYKILRdiZLqmt65eBLENwC-Wz8I/edit?usp=sharing)
