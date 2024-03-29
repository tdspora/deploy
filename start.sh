#!/bin/bash
curl -LO https://raw.githubusercontent.com/tdspora/deploy/main/docker-compose.yml
if [ ! -d "./rabbitconf" ]; then
  mkdir rabbitconf
fi

if test -f ".env"; then
  export $(grep -v '^#' .env | xargs -0)
fi

echo "default_user=${TDM_RABBIT_MQ_USER:-tdm}">./rabbitconf/rabbitmq.conf
echo -n "default_pass=${TDM_RABBIT_MQ_PASSWORD:-pa55w0rd}">>./rabbitconf/rabbitmq.conf

export TDM_HOSTNAME=$(hostname) && docker-compose pull && docker-compose up $@
