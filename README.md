# PSQL-installation
*Steps to install postgresSQL on TACC*\
<br>
Postgress setup requirements - \
**The following environment variables should be set before running the other commands-**
>export POSTGRES_PASS=password \
>export POSTGRES_ADDR=127.0.0.1:5432\
>export POSTGRES_USER=postgres\
>export POSTGRES_DB=venmo
<br>

**To verify if the environment variables are correctly set, the following command can be used -**
>env | grep POSTGRES*

**Commands to run postgres on TACC -**\
Use **singularity** to run all the commands(given below) -\
<br>
#if running on login nodes then use idev
 >idev\
 >module load tacc-singularity\
 >singularity pull docker://postgres\
 >SINGULARITYENV_POSTGRES_PASSWORD=pgpass SINGULARITYENV_PGDATA=$SCRATCH/pgdata singularity run  --cleanenv --bind $SCRATCH:/var postgres_latest.sif&\
 <br>
 #You should see the following message - LOG:  database system is ready to accept connections\
 #Press enter to get back the command prompt
 >psql -U postgres -d postgres -h 127.0.0.1
 
 
 
 
 
 







