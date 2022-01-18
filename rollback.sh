#!/bin/bash
set -e

if [ -f "docker-compose.yml" ]; then
  echo "docker-compose.yml is OK."
else
  echo "docker-compose.yml does not exist! You must put this script
        near to docker-compose.yml file. Exiting..."
  exit 1
fi

CURRENT_DATE="$(date +"%d-%m-%Y")"

#	1. Input a verion for backup in format X.XX.X
echo Please input version number in format X.XX.X
read -r VERSION
echo Component version is: "$VERSION"

POSTGRES_DOCKER="$(docker-compose ps | grep postgres | awk '{ print $1 }')"
echo tdm postgres container is: "$POSTGRES_DOCKER"

#	2. Create a folder for backup files Ex. backup_<timestamp>
mkdir ~/"$CURRENT_DATE"

#	3. Make a full backup of current TDM database timestamp.dump and paste it from docker container to backup folder.
docker restart "$POSTGRES_DOCKER"
sleep 5
docker exec -u postgres "$POSTGRES_DOCKER" bash -c "pg_dumpall >/tmp/$CURRENT_DATE.dump"

#	4. Copy all contents from current folder backup folder
docker cp "$POSTGRES_DOCKER":/tmp/"$CURRENT_DATE".dump ~/"$CURRENT_DATE"
cp docker-compose.yml ~/"$CURRENT_DATE"

#	5. docker-compose down
docker-compose down
docker volume ls --filter name=.jars -q | xargs docker volume rm -f

#	6. download appropriate version from github
cp -R rabbitconf ~/"$CURRENT_DATE"
rm -rf rabbitconf
curl -LO https://raw.githubusercontent.com/epmc-tdm/deploy/"$VERSION"/start.sh
curl -LO https://raw.githubusercontent.com/epmc-tdm/deploy/"$VERSION"/docker-compose.yml
sed '2 {s/^/#/}' start.sh >temp.file && mv temp.file start.sh # comment line in start.sh file

#	7. replace latest tag for ridler17 docker containers to appropriate version
sed -i "s/:latest/:$VERSION/g" docker-compose.yml

chmod +x start.sh && ./start.sh -d
