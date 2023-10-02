#!/bin/bash

#......................................................................
#  E D I T:   S L U R M   A R R A Y   J O B    D E T A I L S
#......................................................................
#SBATCH --job-name=Merge
#SBATCH --time=11:59:00
#SBATCH --account=s3673
#SBATCH --mail-user brycecurrey93@gmail.com
#SBATCH --mail-type=ALL

module load cdo

inpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling/outputs/chunks/"
outpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling/outputs/"

# The CDO_PCTL_SIZE=small reduces the verbosity of cdo outputs and suppresses the appending of history information.
export CDO_PCTL_SIZE=small
cdo merge $inpath/lpj-prosail_levelC_DR_Version003_1km_m_2020_*.nc $outpath/lpj-prosail_levelC_DR_Version003_1km_m_2020.nc
unset CDO_PCTL_SIZE












