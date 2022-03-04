# TNRIS Lidar DEM tiles at TACC

@TACC now hosts TNRIS Lidar tiles for TACC users.

To begin using TACC resources, please create a TACC account at the following page:
https://portal.tacc.utexas.edu/account-request

Once you have a TACC account, submit a ticket at the following page and CC dhl@tacc.utexas.edu
https://portal.tacc.utexas.edu/tacc-consulting

# Software requirements (on Stampede2)
   - Singularity image : `docker://dhardestylewis/postgis:14-3.2-gdalogr`
   - Conda environment : `https://github.com/dhardestylewis/TNRIS-Lidar-PostgreSQL/edit/main/environment.yml`

## Singularity download and usage

This Singularity image includes support for the following 3 PostgreSQL - GDAL/OGR translators:
   - `raster2pgsql` : to create a PostgreSQL script to add rasters to a PostgreSQL table
   - `shp2pgsql` : to create a PostgreSQL script to add features from a Shapefile to a PostgreSQL table
   - `pgsql2shp` : to create a Shapefile from an existing PostgreSQL table

To download this Singularity image, use the following commands from Stampede2:
```bash
## to enter a computational node: Singularity cannot be used from a development node
idev
## to load the pre-existing Singularity module from TACC's module repository
module load tacc-singularity
## to download this Singularity image from the online Docker Hub image repository
singularity pull docker://dhardestylewis/postgis:14-3.2-gdalogr
```

To connect to the existing TNRIS Lidar PostgreSQL database, use the following command:
```bash
cp -R /work2/04950/dhl/stampede2/pgdata $SCRATCH
rm $SCRATCH/pgdata/postmaster.pid
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run --cleanenv --bind $SCRATCH:/var postgis_14-3.2-gdalogr.sif &
```
Please submit a ticket if you don't have permission to access this database and be sure to CC dhl@tacc.utexas.edu

https://portal.tacc.utexas.edu/tacc-consulting

*Note :* Please wait for the following output before trying to access this database:
```bash
LOG:  database system is ready to accept connections
```

# To populate the database with newly added tiles, the following commands can be used to generate a list of raster tiles to add to the table:

From the parent directory of TNRIS Lidar data, on the command line:
```bash
cd <parent_directory_of TNRIS Lidar Data>
find $(pwd) -maxdepth 4 -type f -wholename "*/dem/*.tif" -o -wholename "*/dem/*.img" -o -wholename "*/dem/*.dem" > $WORK/find_dem_tiles.csv
sort -u $WORK/find_dem_tiles.csv > $WORK/find_dem_tiles-sorted.csv
mv $WORK/find_dem_tiles-sorted.csv $WORK/find_dem_tiles.csv
```

From the PostgreSQL database:
```sql
/* replace the following CSV path with your equivalent */
COPY (SELECT absolutepath FROM tnris_lidar_tiles ORDER BY absolutepath) TO '$SCRATCH/select_all_dem_tiles.csv' (FORMAT csv) ;
```

```bash
comm -23 $SCRATCH/find_dem_tiles.csv $SCRATCH/select_all_dem_tiles.csv > $WORK2/missing_dem_tiles.csv

## Run raster2pgsql from the Singularity image
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity exec --cleanenv --bind $SCRATCH:/var postgis_14-3.2-gdalogr.sif bash
```
```bash
## From the Singularity container connected to the database
raster2pgsql -R -F -Y -I -M -e $(cat $WORK2/missing_dem_tiles.csv | tr "\n" " ") public.missing_dem_tiles > $WORK2/missing_dem_tiles.sql

## Once this is done, load the tiles' metadata to the PostgreSQL database using the following command
psql -U postgres -d postgres -h 127.0.0.1 -f $WORK2/missing_dem_tiles.sql
```

From the PostgreSQL database:
```sql
CREATE TABLE missing_dem_tiles_paths (absolutepath text) ;
/* Be sure to replace the following CSV path with your specific CSV path */
COPY missing_dem_tiles_paths FROM '$WORK2/missing_dem_tiles.csv' WITH (FORMAT csv) ;
```

From the command line:
```bash
## Add the following columns to the table:
##     - project
##     - filename
##     - absolutepath
##     - srid_orig
##     - srid
##     - pixeltype
##     - x
##     - y
##     - width
##     - height
## and populate the following columns with metadata:
##     - project : TNRIS Lidar project parent directory name
##     - filename : TRNIS Lidar tilename
##     - absolutepath : TNRIS Lidar tile absolute path on Stampede2
##     - srid_orig : originally found SRID/EPSG code of the tile
##     - srid : corrected SRID/EPSG code of the tile
##     - pixeltype : datatype of the pixels of the tile (float, integer, etc)
##     - width : width of the tile in pixels
##     - height : height of the tile in pixels
psql -U postgres -d postgres -h 127.0.0.1 -f $TNRIS_LIDAR_POSTGRESQL/tnris_lidar_tiles_update1.sql
```

From the PostgreSQL database:
```sql
/* Check to see if the GDAL driver failed to find any of the tiles' projections */
SELECT COUNT(DISTINCT(absolutepath)) FROM missing_dem_tiles WHERE srid_orig = 0 ;
/* If any tiles are found above, it will be necessary to correct the projection information for these tiles. I leave it to the user to determine how to do that. I provide the `srid` column to record corrected projections. Once all of the tiles' projections have been corrected, the following selection should return 0 */
SELECT COUNT(DISTINCT(absolutepath)) FROM missing_dem_tiles WHERE srid = 0 ;
```

From the command line:
```bash
## Populate the following columns with correct(ed) metadata:
##     - rast : raster tile geometry in the corrected SRID/EPSG code)
##     - envelope : envelope of the raster tile
##     - envelope_albers : envelope reprojected to NAD83(2011) / Texas Centric Albers Equal Area
##     - centroid : centroid of the envelope
##     - centroid_albers : centroid reprojected to NAD83(2011) / Texas Centric Albers Equal Area
##     - x : latitudinal coordinate of the centroid in original projection
##     - y : longitudinal cooridnate of the centroid in the orignal projection
psql -U postgres -d postgres -h 127.0.0.1 -f $TNRIS_LIDAR_POSTGRESQL/tnris_lidar_tiles_update2.sql
```

From the PostgreSQL database:
```sql
/* Join the original table with the missing tiles table */
CREATE TABLE updated_tnris_lidar_tiles AS (SELECT rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height FROM tnris_lidar_tiles UNION SELECT rast, filename, absolutepath, project, srid, srid_orig, pixeltype, envelope, envelope_albers, centroid, centroid_albers, x, y, width, height FROM missing_dem_tiles) ;
DROP TABLE tnris_lidar_tiles ;
DROP TABLE missing_dem_tiles ;
ALTER TABLE updated_tnris_lidar_tiles RENAME TO tnris_lidar_tiles ;
```

Once this table is corrected, the following command can be run from the PostGIS Singularity image command line to generate a new TNRIS Lidar availability file:
```bash
pgsql2shp -f $WORK2/TNRIS-Lidar-Corrected_availability_file.shp -h 127.0.0.1 -P pgpass -u postgres -g envelope_albers -k postgres public.tnris_lidar_tiles
```

*QAQC :* Keep in mind that a visual inspection of the resulting Shapefile is necessary in order to ensure that the tiles are all now in the correct projection.

PostgreSQL:
```sqlthe
/* Replace with your preferred location below */
COPY (SELECT DISTINCT(srid) FROM tnris_lidar_tiles) TO '/scratch/04950/dhl/distinct_srid.csv' (FORMAT csv) ;
```

Command line:
```bash
## Please note that any tiles whose pixeltype != Float32 will need to be pre-treated with the following command before starting this workflow.
##  Thus far, ~142 tiles from the following two projects are impacted:
##   - capcog-2007-140cm-caldwell-travis-williamson
##   - usgs-2016-70cm-middle-brazos-lake-whitney
# gdal_translate -ot Float32 src_dataset dst_dataset.vrt
## It will be necessary to substitute in these VRTs for the source tiles in the following `gdalbuildvrt` file lists

## Create a file list of each tileset grouped by SRID/EPSG code:
while read srid; do psql -d postgres -t -A -F"," -c "SELECT absolutepath FROM tnris_lidar_tiles WHERE srid = ${srid}" > ${srid}.srid ; done < /scratch/04950/dhl/distinct_srid.csv

## Conduct a `gdalbuildvrt` for each unique EPSG:
for filename in $(ls *.srid); do gdalbuildvrt -resolution highest -allow_projection_difference -vrtnodata -9999. -a_srs EPSG:$(basename ${filename} .srid) -input_file_list ${filename} -overwrite ${filename}.vrt; done

## Conduct a `gdal_translate` for each unique EPSG's VRT:
for filename in $(ls *.srid); do gdal_translate -colorinterp undefined ${filename}.vrt ${filename}-translated.vrt; done

## Conduct a `gdalwarp` for each unique EPSG's VRT:
for filename in $(ls *.srid); do gdalwarp -t_srs EPSG:3083 -multi -overwrite -setci ${filename}-translated.vrt ${filename}-warped.vrt; done

## EPSGs 2277-2279 will require manual intervention in order to tile successfully.
## They have a vertical datum of NAVD88 (ftUS).
## Run the following command to shift their pixel values to NAVD88 (m):
for filename in $(ls 227[7-9].srid); do gdalwarp -s_srs $(basename ${filename} .srid)+6360 -t_srs EPSG:3083+5703 -multi -overwrite -setci ${filename}-translated.vrt ${filename}-warped.vrt; done

## Conduct a `gdalbuildvrt` to create a VRT of warped VRTs:
gdalbuildvrt -resolution highest albers-warped.vrt *-warped.vrt

## Conduct a retiling:
mkdir albers-warped.d
gdal_retile.py -overlap 100 -tileIndex albers-warped.shp -csv albers-warped.csv -ps 1600 1600 -levels 20 -resume -targetDir albers-warped.d albers-warped.vrt

## Create a VRT of the retiles:
gdalbuildvrt -resolution highest albers-warped.d.vrt albers-warped.d/*.tif


## Crop watershed-delineated DEMs from these retiles, using features labelled by the `index` attribute in a separate vector image
mkdir HUCs.d
NUMBER_OF_HUCS=739
for huc in $(seq 0 $(( ${NUMBER_OF_HUCS} - 1)) ); do gdalwarp -multi -cutline HUCs.shp -cl HUCs -cwhere "index=${huc}" -crop_to_cutline albers-warped.d.vrt HUCs.d/HUC${huc}.tif ; done
```

# Testing environment
- [Stampede2](https://www.tacc.utexas.edu/systems/stampede2)
- [KNL node](https://portal.tacc.utexas.edu/user-guides/stampede2#knl-compute-nodes)
```bash
1) intel/18.0.2      3) impi/18.0.2   5) autotools/1.1    7) cmake/3.16.1   9) TACC
2) libfabric/1.7.0   4) git/2.24.1    6) python2/2.7.15   8) xalt/2.10.2
```
