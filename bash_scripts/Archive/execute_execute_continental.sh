#!/bin/bash


path='/discover/nobackup/bcurrey/PFT_downscaling/'
# could do this by country
continents=("'Eurasia'" "'Africa'" "'South America'" "'Australia'" "'North America'")
abrv=('Eu' 'Af' 'SA' 'Au' 'NA')
len=${#continents[@]}

for (( i = 0; i < $len; i++ )); do
    sed -i "6s|.*|#SBATCH --job-name=PFT_${abrv[$i]}|" $path/execute_LPJ_downscaling_continental.sh
    sed -i "23s|.*|export continent=${continents[$i]}|" $path/execute_LPJ_downscaling_continental.sh
    sed -i "24s|.*|export abrv=${abrv[$i]}|" $path/execute_LPJ_downscaling_continental.sh

    sbatch $path/execute_LPJ_downscaling_continental.sh
done




