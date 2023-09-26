#!/bin/bash

#......................................................................
#  E D I T:   S L U R M   A R R A Y   J O B    D E T A I L S
#......................................................................
#SBATCH --job-name=Chunk
#SBATCH --time=02:59:00
#SBATCH --account=s3673
# --mail-user brycecurrey93@gmail.com
# --mail-type=END
# --mail-type=FAIL


module load cdo
module load nco
module load gdal

dir="/discover/nobackup/bcurrey/PFT_downscaling/"
datapath="$dir/data/"
MODIS_tif="MODIS_PFT_Type_5_clean_crop.tif"
MODIS_nc="MODIS_PFT_Type_5.nc"
outpath="/discover/nobackup/projects/SBG-DO/bcurrey/PFT_downscaling/outputs/chunks/"
varname="PFT"
# ~~ Modify the MODIS PFT GeoTIF ~~
# run gdal conversion
gdal_translate -of NetCDF -a_nodata -9999 -ot Int16 -a_srs "+proj=longlat +ellps=WGS84 +datum=WGS84 +no_defs"  $datapath/$MODIS_tif $datapath/$MODIS_nc
# rename the variable
ncrename -v Band1,$varname $datapath/$MODIS_nc
# invert lat dimension (gdal flips it)
cdo invertlat $datapath/$MODIS_nc $datapath/corrected.nc
# overwrite back to old name
mv $datapath/corrected.nc $datapath/$MODIS_nc

# Set output name, which will be appended by the chunk number (1-100)
output="MODIS_PFT_Type_5_"

# Get the total number of lon and lat
total_lon=$(cdo griddes $datapath/$MODIS_nc | grep xsize | awk '{print $3}')
total_lat=$(cdo griddes $datapath/$MODIS_nc | grep ysize | awk '{print $3}')

echo -e "total lon = $total_lon"
echo -e "total lat = $total_lat"

# Determine number of chunks for lon and lat
num_lon_chunks=10
num_lat_chunks=10

# calculate lon and lat size (typically 4000 x 2000)
lon_chunk_size=$(( total_lon / num_lon_chunks ))
lat_chunk_size=$(( total_lat / num_lat_chunks ))

echo -e "lon chunk size: $lon_chunk_size"
echo -e "lat chunk size: $lat_chunk_size"


# Loop to split NetCDF by lon and lat indices
export chunk_index=1
for (( ix=1; ix<=$total_lon; ix+=lon_chunk_size )); do
    for (( iy=1; iy<=$total_lat; iy+=lat_chunk_size )); do

        # Calculate the lon and lat index range for the current chunk
        lon_end=$(( ix + lon_chunk_size - 1 ))
        lat_end=$(( iy + lat_chunk_size - 1 ))
        echo -e "Chunk: [$ix, $lon_end, $iy, $lat_end] [ix, lon_end, iy, lat_end]"
        
        # pass MODIS path to execute_PFT_downscaling_byChunk.sh  
        export MODIS_NC="$outpath/${output}${chunk_index}.nc"
       
        # if the chunked modis file already exists, skip to sbatch
        if [[ ! -f $MODIS_NC ]]; then
       
            # Use CDO to select the index box and create the chunk
            cdo selindexbox,$ix,$lon_end,$iy,$lat_end $datapath/$MODIS_nc ${outpath}/${output}${chunk_index}.nc
            # Test for no data (all values are zero)
            max_value=$(cdo output -fldmax $MODIS_NC)
            echo -e $max_value
            rm -f $outpath/temp_variable.nc 

            if [[ $max_value -eq 0 ]]; then
                echo -e "Skipping chunk $chunk_index because all values are zero."
            else
                # sbatch execute script.
                sbatch --job-name="Chunk-$chunk_index"  $dir/execute_LPJ_downscaling_byChunk.sh
            fi
        
        else
           
           sbatch --job-name="Chunk-$chunk_index"  $dir/execute_LPJ_downscaling_byChunk.shi
        
        fi
        
        # increase chunk_index by 1 
        export chunk_index=$(( chunk_index + 1 ))
    done
done


