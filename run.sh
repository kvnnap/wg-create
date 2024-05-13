#!/bin/bash

docker build -t kvnnap/wg-create .devcontainer/
docker run --rm -it -v $PWD:/home/ubuntu/wg-create -w /home/ubuntu/wg-create --env-file config.env kvnnap/wg-create:latest ./gen.sh

