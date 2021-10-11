#!bin/bash
curl -LO https://raw.githubusercontent.com/epmc-tdm/deploy/main/docker-compose.yml && \
mkdir rabbitconf

if test -f ".env"; then
export $(grep -v '^#' .env | xargs -0)
fi

echo "default_user=${TDM_RABBIT_MQ_USER:-tdm}">./rabbitconf/rabbitmq.conf
echo -n "default_pass=${TDM_RABBIT_MQ_PWD:-pa55w0rd}">>./rabbitconf/rabbitmq.conf
