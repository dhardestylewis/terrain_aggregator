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

To initiate a new PostgreSQL+PostGIS database on Stampede2, you may use the following command:
```bash
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run --cleanenv --bind $SCRATCH:/var postgis_14-3.2-gdalogr.sif &
```

To connect to the existing TNRIS Lidar PostgreSQL database, use the following command:
```bash
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=/work2/04950/dhl/stampede2/pgdata singularity run --cleanenv --bind $SCRATCH:/var postgis_14-3.2-gdalogr.sif &
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
COPY (SELECT absolutepath FROM tnris_lidar_tiles ORDER BY absolutepath) TO '/work2/04950/dhl/stampede2/select_all_dem_tiles.csv' (FORMAT csv) ;
```

```bash
comm -23 $SCRATCH/find_dem_tiles.csv /work2/04950/dhl/stampede2/select_all_dem_tiles.csv > $WORK2/missing_dem_tiles.csv

## Run raster2pgsql from the Singularity image
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$WORK2/pgdata singularity exec --cleanenv --bind $SCRATCH:/var postgis_14-3.2-gdalogr.sif bash
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
COPY missing_dem_tiles_paths FROM '/work2/04950/dhl/stampede2/missing_dem_tiles.csv' WITH (FORMAT csv) ;
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

# PostgreSQL+PostGIS installation using Singularity on Stampede2

*Steps to install PostgreSQL+PostGIS on Stampede2 at TACC*

Installation of a containerized instance of PostgreSQL in a high performance computing environment (Stampede2)


# Motivation 

Containerized PostgreSQL is a useful step to create, manage, 
and access PostgreSQL databases directly on an HPC environment. 

Containerizing the database software enables use by HPC web-portals
such as:
- [PT2050 DataX](https://ptdatax.tacc.utexas.edu/),
- [DesignSafe-CI](https://www.designsafe-ci.org/), 
- [the TACC visualization portal](https://vis.tacc.utexas.edu/),
- [SkySQL](https://mariadb.com/products/skysql/)


# Limitations 
- This has been tested on Stampede2 supercomputer at [@TACC](https://github.com/TACC)
- This can only be run on allocated computational nodes.
  On Stampede2 the [max allocated time](https://portal.tacc.utexas.edu/user-guides/stampede2#queues) available is 5 days 


# Prerequisite software
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)
- Shell environment, *eg* `bash`, `zsh`, *etc*


# Installation Method


[//]: # (This entire section may be unnecessary.)
[//]: # (TODO: test next subsection of instructions without running these commands first.)
## PostgreSQL setup requirements
If on a login node, then enter a computational node by executing the following command:
```bash
idev
```
**The following environment variables may need to be set before continuing**
```bash
export POSTGRES_PASS=password
export POSTGRES_ADDR=127.0.0.1:5432
export POSTGRES_USER=postgres
export POSTGRES_DB=postgres
```

**To verify if the environment variables are correctly set, the following command can be used**
```bash
env | grep POSTGRES*
```


## **Commands to run PostgreSQL at TACC**
[\\]: # (Use **Singularity** to run all the commands, given below)

```bash
module load tacc-singularity
```

## Use the following commands to pull & inititiate a PostgreSQL database instance

```bash
singularity pull docker://postgres  ## singularity pull has to be done only once
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run --cleanenv --bind $SCRATCH:/var postgres_latest.sif &
```

## OR use the following commands to pull & initiate a PostgreSQL+PostGIS database instance

```bash
singularity pull docker://postgis/postgis  ## singularity pull has to be done only once
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run --cleanenv --bind $SCRATCH:/var postgis_latest.sif &
```

## You should see the following message

```bash
LOG:  database system is ready to accept connections
```

## Press enter to get back the command prompt and then run the following command to connect to the PostgreSQL database instance

```bash
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity exec --cleanenv --bind $SCRATCH:/var postgres_latest.sif psql -U postgres -d postgres -h 127.0.0.1
```
(Note: There is an existing version of `psql` on Stampede2, we suggest using `psql` from the Singularity image like shown above.)

Note : Instead of SCRATCH/pgdata you can use any database on stampede2 that you have access to.

# Testing environment
- [Stampede2](https://www.tacc.utexas.edu/systems/stampede2)
- [KNL node](https://portal.tacc.utexas.edu/user-guides/stampede2#knl-compute-nodes)
```bash
1) intel/18.0.2      3) impi/18.0.2   5) autotools/1.1    7) cmake/3.16.1   9) TACC
2) libfabric/1.7.0   4) git/2.24.1    6) python2/2.7.15   8) xalt/2.10.2
```


# Alternatives 
`/bin/psql` is available on Stampede2 without relying on Singularity/Docker. We have not tested here strictly using the pre-installed PostgreSQL software to initiate a database instance.
 
 
# This installation method was inspired by [sshh12/venmo-research](https://github.com/sshh12/venmo-research)






