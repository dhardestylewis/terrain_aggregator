 
 
# PostgreSQL installation using Singularity on Stampede2
*Steps to install PostgreSQL on Stampede2 at TACC*
Installation of a containerized instance of PostgreSQL in a high performance computing environment (Stampede2)


# Motivation 
Containerized PostgreSQL is useful step to create, manage, 
and access PostgreSQL databases directly on HPC environments 
using HPC web-portals similar to
[PT2050 DataX](https://ptdatax.tacc.utexas.edu/),
[DesignSafe-CI](https://www.designsafe-ci.org/), 
[the TACC visualization portal](https://vis.tacc.utexas.edu/), or
[SkySQL](https://mariadb.com/products/skysql/)


# Limitations 
- This has been tested on Stampede2 supercomputer at [@TACC](https://github.com/TACC)
- This can only be run on allocated computational nodes.
  On Stampede2 the [max allocated time](https://portal.tacc.utexas.edu/user-guides/stampede2#queues) available is 5 days 


# Pre-requisite software
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)
- Shell environment, *eg* `bash`, `zsh`, *etc*


# Installation Method


[//]: # (This entire section may be unnecessary.)
[//]: # (TODO: test next subsection of instructions without running these commands first.)
## PostgreSQL setup requirements
If running on login nodes then use idev
```bash
>idev
```
#**The following environment variables should be set before running the other commands-**
```bash
export POSTGRES_PASS=password
export POSTGRES_ADDR=127.0.0.1:5432
export POSTGRES_USER=postgres
export POSTGRES_DB=postgres
```

**To verify if the environment variables are correctly set, the following command can be used -**
```bash
env | grep POSTGRES*
```


## **Commands to run PostgreSQL at TACC**
[\\]: # (Use **Singularity** to run all the commands (given below))
```bash
module load tacc-singularity
singularity pull docker://postgres  ## singularity pull has to be done only once
SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run  --cleanenv --bind $SCRATCH:/var postgres_latest.sif &
```
## You should see the following message -
```bash
LOG:  database system is ready to accept connections
```
## Press enter to get back the command prompt and then run the following command
```bash
psql -U postgres -d postgres -h 127.0.0.1
```


# Testing environment
- [Stampede2](https://www.tacc.utexas.edu/systems/stampede2)
- [KNL node](https://portal.tacc.utexas.edu/user-guides/stampede2#knl-compute-nodes)
```bash
1) intel/18.0.2      3) impi/18.0.2   5) autotools/1.1    7) cmake/3.16.1   9) TACC
2) libfabric/1.7.0   4) git/2.24.1    6) python2/2.7.15   8) xalt/2.10.2
```


# Alternatives 
`/bin/psql` is available on Stampede2 without relying on Singularity/Docker. We have not tested here an initiation of PostgreSQL database using strictly this installation.
 
 
# This installation method was inspired by [sshh12/venmo-research](https://github.com/sshh12/venmo-research)

