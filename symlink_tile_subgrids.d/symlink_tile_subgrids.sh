#!/bin/bash
## Scalable subgrid symlinking workflow, for reference
## Copyright 2022 Daniel Hardesty Lewis
## Licensed under GPLv3+
## https://www.gnu.org/licenses/gpl-3.0.txt

GEOSERVER_DATA=/var/lib/tomcat9/webapps/geoserver/data
SCRIPT_DIR=$( cd -- "$( dirname -- "${BASH_SOURCE[0]}" )" &> /dev/null && pwd )

cd ${GEOSERVER_DATA}
mkdir TNRIS_Lidar_retiling_symlinks

cd TNRIS_Lidar_retiling_symlinks
for i in $( seq 0 20 ) ; do
    mkdir ${i}
done

regrid_tiles () {
    while read f ; do
        IFS=_ read projection subgrid_clm subgrid_row tile_clm tile_row <<< $( basename ${f} .tif )
        new_tile_clm=$( printf %04d $(( 10#${subgrid_clm} * 166 + 10#${tile_clm} )) )
        new_tile_row=$( printf %04d $(( 10#${subgrid_row} * 166 + 10#${tile_row} )) )
        ln -s ${f} 3083_${new_tile_clm}_${new_tile_row}.tif
    done < ${1}
}

cd 0

cat ${SCRIPT_DIR}/base_tiles[0-2].txt > ${GEOSERVER_DATA}/base_tiles.txt
base_tiles="${GEOSERVER_DATA}/base_tiles.txt"
regrid_tiles "${base_tiles}"

cd ..
cat ${SCRIPT_DIR}/zoom_tiles[01].txt > ${GEOSERVER_DATA}/zoom_tiles.txt
for i in $( seq 1 20 ) ; do
    zoom_tiles="${GEOSERVER_DATA}/zoom_tiles.txt"
    cd ${i}
    regrid_tiles "${zoom_tiles}"
    cd ..
done

