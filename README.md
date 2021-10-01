# Deployment Scripts
The repository for `docker-compose` files.  
The files reference private Docker Hub repository and cannot be used without proper login.  
If you feel authorized, please request the access from the authors.

# TDM installation process

Please make sure you have an acces to private docker repo for download TDM.

## How to install TDM from scratch

1. Download `start.sh` file and execute it

```sh
bash start.sh
```

2. Start installation

```sh
export TDM_HOSTNAME=$(hostname) && docker-compose pull && docker-compose up -d
```

## Configuration
If you want to change some of the default values
- Create file `.env` in the same folder as `docker-compose.yml`
- Add values from the list below you would like to override
### Environment variables
```ini
TDM_FERNET_KEY=jNICCd9MFHW++hGZ9cUAGmsdOCUCtcaI1ZM+2F+pXGs=
```
Encryption key for the Spark job descriptors that can contain secrets such as database user and password. 
The simpliest way to generate new key is to run `dd if=/dev/urandom bs=32 count=1 2>/dev/null | openssl base64` in `bash`.

---
```ini
COMPOSE_PROJECT_NAME=local
```
All the containers will have this prefix added to the container name.

---
```ini
TDM_ADMIN_EMAIL=admin@companyname.com
```
Not used. Will be implemented later.

---
```ini
TDM_ADMIN_USERNAME=admin
```
Administrator user name. This is theonly user name supported.

---
```ini
TDM_ADMIN_PASSWORD=<password>
```
Administrator password. There is no rules or limitation for the password complexity.

---
```ini
TDM_APPLICATION_KEY=594df9ea-3565-4145-b9c4-9bbc47ff6200
```
UUID for the application. Static value used in combination with API key to access REST API.

---
```ini
TDM_RABBIT_MQ_USER=tdm
```
User name for the RabbitMQ container.

---
```ini
TDM_RABBIT_MQ_PASSWORD=<rabbit_mq_password>
```
Password for the default RabbitMQ user.

---
```ini
TDM_SPARK_SSH_USER=tdm
```
Name of the user the application use to access internal Spark container and submitting Spark jobs.

---
```ini
TDM_SPARK_SSH_PASSWORD=<spark_ssh_password>
```
Password for the SSH user.

---
```ini
TDM_DB_USER=tdm
```
User name the application will use to access internal PostgreSQL instance.

---
```ini
TDM_DB_PASSWORD=<tdm_db_password>
```
The PostgreSQL user password.

---
```ini
TDM_POSTGRES_PORT=5432
```
The internal PostgreSQL instance will expose this port for external connections.

---
```ini
TDM_PORT=80
```
The user interface for the application will be available on this port. Default URL: http://localhost:80/

---
```ini
TDM_UI_REFINITIV_PORT=32082
```
The application user interface with altered theme will be available on this port. Default URL: http://localhost:32082/

---
```ini
TDM_SPARK_UI_PORT=8080
```
The port exposed for the Apache Spark master node UI.

---
```ini
TDM_SPARK_HISTORY_PORT=18080
```
The port exposed for the Apache Spark History Server UI.

---
```ini
TDM_LOG_LEVEL=DEBUG
```
Granularity level of logs collected during execution of pipelines. Valid values are ALL, TRACE, DEBUG, INFO, WARN, ERROR, FATAL, and OFF.

---
```ini
TDM_HOSTNAME=localhost
```
The FQDN of the host serving the application REST API endpoints. Along with `TDM_API_PORT` defines full URL (`TDM_URL`) that the backend includes into job descriptors. The pipelines execution engine reports status of the job to the `${TDM_URL}/v1/executions/<executionId>/progress` endpoint. If this endpoint is not accessible from the Apache Spark cluster, the status will not be updated dynamically, but only at the end of the job execution.

---

# Maintenance

## Upgrading and restoring repository contents

If you are performing an upgrade you have to backup all your data saved into TDM tool.
Since we use postgres database the backup process is quite simple.

Check the variable `COMPOSE_PROJECT_NAME` in your `.env.` file

```sh
cat .env | grep COMPOSE_PROJECT_NAME
```

1. At first, you have to save data from the Postgres container.
You can run a simple command which will save Postgres dump on your `/tmp` folder (not in the container!)

```sh
docker exec -it -u postgres <project_name>_postgres_1 pg_dumpall > /tmp/tdm.dump
```

**Before you will start the restore process, please make sure you have the dump file in your folder!**

2. Go to the folder with the docker-compose file and stop all the containers

```sh
docker-compose down
```

3. Let's take a look at the volumes we have

```sh
docker volume ls
```

4. Postgres volume must be something like `<compose_project_name>_postgres_1`. Delete it with

```sh
docker volume rm <compose_project_name>_postgres
```

5. Launch TDM with docker-compose

```sh
docker-compose pull && docker-compose up -d
```

6. Do not login into TDM for that moment*.
Copy dump to the container:

```sh
docker cp /tmp/tdm.dump <container_name>:/tmp
```

**If you performed login into TDM you have to restart TDM Postgres container because login operation creating session within Postgres DB and you will not be able to drop database*

7. Login into Postgres container (or use Portainer) with Postgres user and bash shell:

```sh
docker exec -it -u postgres <container_name> bash
```

8. Run the following commands within the Postgres container

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
