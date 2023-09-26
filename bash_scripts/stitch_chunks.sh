#!/bin/bash

#......................................................................
#  E D I T:   S L U R M   A R R A Y   J O B    D E T A I L S
#......................................................................
#SBATCH --job-name=Merge
#SBATCH --time=05:59:00
#SBATCH --account=s3673
# --mail-user brycecurrey93@gmail.com
# --mail-type=ALL

module load cdo
outpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling/outputs/"

cdo merge $outpath/lpj-prosail_levelC_DR_Version022_1km_m_2020_*.nc $outath/lpj-prosail_levelC_DR_Version022_1km_m_2020.nc













