#!/bin/bash

#......................................................................
#  E D I T:   S L U R M   A R R A Y   J O B    D E T A I L S
#......................................................................
#SBATCH --job-name=RGB
#SBATCH --time=11:59:00
#SBATCH --account=s3673
#SBATCH --mail-user brycecurrey93@gmail.com
#SBATCH --mail-type=ALL

module load cdo

inpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling/outputs/chunks/"
outpath="/discover/nobackup/bcurrey/PFT_downscaling/data/RGB/"

for (( chunk = 1; chunk <= 100; chunk++ )); do
    in_nc="$inpath/lpj-prosail_levelC_DR_Version003_1km_m_2020_${chunk}.nc"
    out_nc="$outpath/lpj-prosail_levelC_DR_RGB_1km_m_2020_${chunk}.nc"
     if [[ -e "$in_nc" ]]; then
         # extract RGB bands for July
         cdo -L -s -sellevel,460,540,630 -seldate,2020-07-01,2020-07-30 $in_nc $out_nc 
     else
         echo "File $in_nc does not exist. Skipping."
     fi
     echo -e $in_nc
done

# The CDO_PCTL_SIZE=small reduces the verbosity of cdo outputs and suppresses the appending of history information.
export CDO_PCTL_SIZE=small
cdo merge $outpath/lpj-prosail_levelC_DR_RGB_1km_m_2020_*.nc $outpath/lpj-prosail_levelC_DR_RGB_1km_m7_2020.nc
unset CDO_PCTL_SIZE
# convert to geotif










