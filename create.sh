#!/bin/bash

echo "Creating keys and server config"

docker build -t kvnnap/wg-create .devcontainer/
docker run --rm -it -v $PWD:/home/ubuntu/wg-create -w /home/ubuntu/wg-create --env-file config.env kvnnap/wg-create:latest ./gen.sh

echo "Ready to deploy wireguard container inside wgsrv"

