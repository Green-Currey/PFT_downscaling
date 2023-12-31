#!/bin/bash

#......................................................................
#  E D I T:   S L U R M   A R R A Y   J O B    D E T A I L S
#......................................................................
#SBATCH --job-name=PFT
#SBATCH --time=11:59:00
#SBATCH --account=s3673
#SBATCH --mem=180G
# --mem-per-cpu=15000
# --constraint=sky
# --mail-user brycecurrey93@gmail.com
# --mail-type=END
# --mail-type=FAIL

# This script executes the paint.by.PFT() function by way of LPJ_PFT_downscaling.R 

# LPJ Global output directory.
#   ...must have fpc and reflectance NCDFs
rundir='LPJ-PROSAIL-maxfpc'

export chunksize=500    #in km2
export year=2020
export reflectanceType="DR"
export version="LPJ_maxfpc_v2.0"

export scriptspath="/discover/nobackup/bcurrey/PFT_downscaling2/scripts/"
export inpath="/discover/nobackup/bcurrey/PFT_downscaling2/data/"
export lpjpath="/discover/nobackup/projects/SBG-DO/bcurrey/global_run_simulations/${rundir}/ncdf_outputs/"
export outpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling2/outputs/"
export outname="LPJ_prosail_levelC_${reflectanceType}_Version022_1km_m_${year}.nc"


Rscript $scriptspath/LPJ_PFT_downscaling2.R


