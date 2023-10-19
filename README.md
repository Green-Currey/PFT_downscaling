# PFT_downscaling
## This repo contains the scripts to downscale LPJ-PROSAIL data by mapping LPJ spectra to MODIS MCD12Q1 Type 5 PFT data using a "paint-by-numbers" approach.

### The process to downscale the LPJ data to MODIS Type 5 PFT data is as follows:
1. Divide the MODIS PFT Type 5 geotif into 100 uniform gridded boxes (_refered to as 'chunks'_, see figure below). Each of these gets submitted as its own job on discover.
    - Each of these is 4000km x 2000 km
    - **NOTE**: If the entire box has no PFT, the next step is skipped.
2. Within each 8M km2 chunk, we subdivide the region into 500km x 500km '_subchunks_' for the analysis to run
    - **NOTE**: This is necessary for 1) time constraints of running on discover, and 2) are small enough to be written using R into the NetCDF.
3. For each 250k km2 subchunk, loop through each 1km2 grid cell and examine the MODIS PFT value and extract relevant hyperspectral data. The process is as follows:
4. Selected spectra are mapped to the same resolution as the MODIS PFT map (1km)
5. These data are written to the 8M km2 NetCDF chunk.
    - **NOTE**: Because a NetCDF file is NOT created if there are no PFT data, there are slightly less than 100 files.

### Scripts in the pipeline:
1. _LPJ_downscaling_byChunk.sh_ -- This script launches the pipeline.
    1. Converts the MODIS_PFT_Type_5.tif file into NetCDF.
    2. Modifies this new NetCDF (rename, flip latitude, etc).
    3. Divides the new MODIS PFT NetCDF into 100 chunks, 4000x2000km in size.
    4. Checks if all values are zero (no PFT values), if so, the script does not create a NetCDF chunk.
    5. If PFT data exists, the NetCDF chunk is created and passed to the next bash script.
    6. The next bash script is sbatched.
    - **NOTE**: 
2. _execute_LPJ_downscaling_byChunk.sh_ -- This script launches the analysis for each chunked NetCDF.
    1. Passes the necessary file paths and parameters to the R script.
    2. Executes the Rscript.
3. _LPJ_PFT_downscaling_bychunk.R_ -- This script runs the analysis
    1.  Divides the chunk into 500km2 subchunks
    2.  Loops through each 1km2 gridcell
    3.  Calls the function paint_by_PFT() that:
        1. Check if the MODIS PFT value matches the LPJ PFT value.
        2. If a match, extract the spectra for the corresponding LPJ grid cell.
        3. If no match, use LPJ-derived LUT for corresponding spectra.
        - **NOTE**: The latitude of the grid cell is taken into account to pick the most representative LPJ PFT spectra. For example, if the MODIS PFT is _Deciduous Broadleaf_, the LUT will check the latitude to obtain spectra from either _Tropical Broadleaf Raingreen_             or _Temperate Broadleaf Summergreen_ from LPJ. If the latitude is greater than 28 degrees North or South, it chooses the temperate PFT spectra from the LUT; otherwise, the tropical PFT spectra. 
    4.  Writes to the NetCDF file.

### Other scripts:
- _paintByPFT.R_ -- contains all the functions called in the _LPJ_PFT_downscaling_byChunk.R_.
- _create_global_grid.R_ -- Produces a visual grid with numbers to know which NetCDF chunk is which.
- _RGB_visualization_chunk.R_ -- Script that allows you to visualize an individual chunk.
- _stitch_chunks.sh_ -- This script merges all chunk NetCDFs together.
- _RGB_display.sh_ -- This script extracts the RGB bands for a given month for each chunk NetCDF and stitches them together, similar to _stitch_chunks.sh_.

### lpj-version 3 Grid structure
![lpj-prosail_version003_grid](https://github.com/Green-Currey/PFT_downscaling/assets/57914237/033fe5ff-35ff-4e10-bdcf-592ea100b80d)


### More information: 
- LPJ-PROSAIL data: [Poulter et al., 2023. Simulating Global Dynamic Surface Reflectances for Imaging Spectroscopy Spaceborne Missions: LPJ-PROSAIL](https://onlinelibrary.wiley.com/doi/abs/10.1029/2022JG006935)
- MODIS data here: [mcd12q1v006](https://lpdaac.usgs.gov/products/mcd12q1v006/)
- Google slide of the procedure here: [Paint-by-pft approach](https://docs.google.com/presentation/d/1Wh_hnF6Rc1M3smSVDY1JST_kC6i_KZisgWF26pYTGco/edit?usp=sharing)
- Converting Osborne et al., 2014 C3/C4 maps to raster [C3/C4 maps to raster (Google slides)](https://docs.google.com/presentation/d/1uqTXW6YhO1ElM9dWfYKILRdiZLqmt65eBLENwC-Wz8I/edit?usp=sharing)
