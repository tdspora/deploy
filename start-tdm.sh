#!/bin/bash
export TDM_HOSTNAME=`hostname -f`

docker-compose pull && docker-compose up -d
