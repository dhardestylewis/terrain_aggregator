 # For further instructions please refer to [sshh12/venmo-research](https://github.com/sshh12/venmo-research)
 
 # PSQL-installation
*Steps to install postgresSQL on TACC*\
Installation of a containerized instance of PostgreSQL in a high performance computing environment (Stampede2)
<br>
# Motivation 
Containerized PostgreSQL is useful step to create, manage, 
and access PostgreSQL databases directly on HPC environments 
using HPC web-portals similar to PT2050 DataX, DesignSafe-CI, 
the TACC visualization portal, or SkySQL

# Limitations 
- This has been tested on Stampede2 supercomputer at @TACC
- This can only be run on allocated computational nodes. On Stampede2 the [max allocated time](https://portal.tacc.utexas.edu/user-guides/stampede2#queues) available is 5 days 

# Prerequisites softwares
- [Docker](https://www.docker.com/) or [Singularity](https://sylabs.io/singularity/)
- Shell environment - Eg bash etc

# Installation Method
## Postgress setup requirements - \
if running on login nodes then use idev
>idev
<br>#**The following environment variables should be set before running the other commands-**<br>
>export POSTGRES_PASS=password\
>export POSTGRES_ADDR=127.0.0.1:5432\
>export POSTGRES_USER=postgres\
>export POSTGRES_DB=postgres
<br>

**To verify if the environment variables are correctly set, the following command can be used -**
>env | grep POSTGRES*


# Testing environment
- [Stampede2](https://www.tacc.utexas.edu/systems/stampede2)
- [knl node](https://portal.tacc.utexas.edu/user-guides/stampede2#knl-compute-nodes)
```bash
1) intel/18.0.2      3) impi/18.0.2   5) autotools/1.1    7) cmake/3.16.1   9) TACC
2) libfabric/1.7.0   4) git/2.24.1    6) python2/2.7.15   8) xalt/2.10.2
``` 




**Commands to run postgres on TACC -**\
Use **singularity** to run all the commands(given below) -\
<br>
 >module load tacc-singularity\
 >singularity pull docker://postgres\
 >SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run  --cleanenv --bind $SCRATCH:/var postgres_latest.sif&
 <br> #You should see the following message - LOG:  database system is ready to accept connections
 <br> #Press enter to get back the command prompt and then run the following command\
 >psql -U postgres -d postgres -h 127.0.0.1



# Alternatives 
`/bin/psql` is available on Stampede2 without relying on Singularity/docker. However, we have not tested an initiation of postgresSQl 
 
 
 
 
 







