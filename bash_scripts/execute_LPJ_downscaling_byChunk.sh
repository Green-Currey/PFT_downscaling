#!/bin/bash

#......................................................................
#  E D I T:   S L U R M   A R R A Y   J O B    D E T A I L S
#......................................................................
#SBATCH --job-name=PFT
#SBATCH --time=05:59:00
#SBATCH --account=s3673
# #SBATCH --mail-user brycecurrey93@gmail.com
# #SBATCH --mail-type=END
# #SBATCH --mail-type=FAIL

# This script executes the paint.by.PFT() function by way of LPJ_PFT_downscaling.R 

# LPJ Global output directory.
#   ...must have fpc and reflectance NCDFs
#   ...this requires flag DMAXFPC to be turned on in order to pull PFT-specific spectra (e.g., unmixed spectra).
rundir='LPJ-PROSAIL-maxfpc'

export chunksize=500    #in km2
export year=2020
export reflectanceType="DR"
export version="LPJ_maxfpc_v2.0"
export MODIS_nc=$MODIS_NC
export chunk=$chunk_index

export scriptspath="/discover/nobackup/bcurrey/PFT_downscaling/R_scripts/"
export inpath="/discover/nobackup/bcurrey/PFT_downscaling/data/"
export lpjpath="/discover/nobackup/projects/SBG-DO/bcurrey/global_run_simulations/${rundir}/ncdf_outputs/"
export outpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling/outputs/chunks/"
export outname="lpj-prosail_levelC_${reflectanceType}_Version003_1km_m_${year}_${chunk}.nc"

# update: no internal chunking.
Rscript $scriptspath/LPJ_PFT_downscaling_bychunk.R


