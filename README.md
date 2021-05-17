# Deployment Scripts
The repository for `docker-compose` files.  
The files reference private Docker Hub repository and cannot be used without proper login.  
If you feel authorized, please request the access from the authors.

# TDM installation process

Please make sure you have an acces to private docker repo for download TDM.

## How to install TDM from scratch

1). Create folder `tdm-install`

```sh
mkdir tdm-install
```

2). Download main file with `wget`:

```sh
wget https://raw.githubusercontent.com/epmc-tdm/deploy/main/docker-compose.yml
```

Only if you want to override the default values, create `.env` file, fill it with your own values and place near the `docker-compose.yml` file:

```ini
TDM_FERNET_KEY=jNICCd9MFHW++hGZ9cUAGmsdOCUCtcaI1ZM+2F+pXGs=
COMPOSE_PROJECT_NAME=local
TDM_ADMIN_EMAIL=admin@companyname.com
TDM_ADMIN_USERNAME=admin
TDM_ADMIN_PASSWORD=<password>
TDM_APPLICATION_KEY=594df9ea-3565-4145-b9c4-9bbc47ff6200
TDM_RABBIT_MQ_USER=tdm
TDM_RABBIT_MQ_PASSWORD=<rabbit_mq_password>
TDM_SPARK_SSH_USER=tdm
TDM_SPARK_SSH_PASSWORD=<spark_ssh_password>
TDM_DB_USER=tdm
TDM_DB_PASSWORD=<tdm_db_password>
POSTGRES_PASSWORD=<postgres_password>
TDM_POSTGRES_PORT=5432
TDM_UI_PORT=32080
TDM_UI_REFINITIV_PORT=32082
TDM_SWAGGER_UI_PORT=8204
TDM_API_PORT=8202
TDM_SPARK_UI_PORT=8100
TDM_SPARK_WORKER_PORT=8101-8105
TDM_SPARK_HISTORY_PORT=18090
TDM_LOG_LEVEL=DEBUG
```

4). Launch install process:

```sh
docker-compose pull && docker-compose up -d
```

## How to update TDM and restore all your data

If you are performing an upgrade you have to backup all your data saved into TDM tool.
Since we use postgres database the backup process is quite simple.

Check the variable `COMPOSE_PROJECT_NAME` in your `.env.` file

```sh
cat .env | grep COMPOSE_PROJECT_NAME
```

1). At first, you have to save data from the Postgres container.
You can run a simple command which will save Postgres dump on your `/tmp` folder (not in the container!)

```sh
docker exec -it -u postgres <project_name>_postgres_1 pg_dumpall > /tmp/tdm.dump
```

**Before you will start the restore process, please make sure you have the dump file in your folder!**

2). Go to the folder with the docker-compose file and stop all the containers:

```sh
docker-compose down
```

3). Let's take a look at the volumes we have:

```sh
docker volume ls
```

4). Postgres volume must be something like `<compose_project_name>_postgres_1`. Delete it with:

```sh
docker volume rm <compose_project_name>_postgres
```

5). Launch TDM with docker-compose:

```sh
docker-compose pull && docker-compose up -d
```

5). Do not login into TDM for that moment*.
Copy dump to the container:

```sh
docker cp /tmp/tdm.dump <container_name>:/tmp
```

**If you performed login into TDM you have to restart TDM Postgres container because login operation creating session within Postgres DB and you will not be able to drop database*

6). Login into Postgres container (or use Portainer) with Postgres user and bash shell:

```sh
docker exec -it -u postgres <container_name> bash
```

7). Run the following commands within the Postgres container

```sh
psql -U postgres -c "DROP DATABASE tdm;"
psql -U postgres -c "CREATE DATABASE tdm;"
psql -U postgres -d tdm -f /tmp/tdm.dump &> /tmp/restore_tdm.log
```

You can see some errors in log file such as

```sh
psql:/tmp/tdm.dump:14: ERROR: role "postgres" already exists
psql:/tmp/tdm.dump:16: ERROR: role "tdm" already exists
psql:/tmp/tdm.dump:28: ERROR: database "tdm" already exists
psql:/tmp/tdm.dump:30: ERROR: database "tdm_test" already exists
```

It's ok and should not affect on any data.
