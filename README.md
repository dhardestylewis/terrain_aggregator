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

To downlaod this Singularity image, use the following commands from Stampede2:
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
Please submit a ticket if you don't have permission to access this directory and be sure to CC dhl@tacc.utexas.edu
https://portal.tacc.utexas.edu/tacc-consulting

*Note :* Please wait for the following output before trying to access this database:
```bash
LOG:  database system is ready to accept connections
```

To 

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






