#!/usr/bin/env bash

# This script builds the Docker image that will be used to build the openjdk images.
# It also sets up docker in docker with a local registry cache to avoid the rate limit.

set -euxo pipefail

docker build . -t openjdk-builder

docker volume prune -f

docker network create dind-network || true
docker volume create dind-certs-ca || true
docker volume create dind-certs-client || true

(docker stop dind-docker && docker rm dind-docker) || true

CONTAINER_ID=$(
    docker run --privileged --userns=host --name dind-docker -d \
        --network dind-network --network-alias docker \
        -e DOCKER_TLS_CERTDIR=/certs \
        -v dind-certs-ca:/certs/ca \
        -v dind-certs-client:/certs/client \
        docker:dind --registry-mirror=http://localhost:5000
            )

sleep 2 # give the daemon a sec to start up
docker exec -it "$CONTAINER_ID" sh -c "docker run -d -p 5000:5000 -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io --restart=always --name registry registry:2"

# Use a bind mount for the benchmarks to persist data after container exits
mkdir -p ./benchmarks && chmod a+w ./benchmarks

mkdir -p data
# if fewer than needed binaries, then fetch them
if [ "$(ls data -1 | wc -l)" -lt "$(wc -l < binary_filenames.txt)" ]
then
    while read -r filename; do
        echo "$filename"
        wget "https://modus-continens.s3.eu-west-2.amazonaws.com/fse22-artifact-data/$filename" -O "data/$filename"
    done <binary_filenames.txt
fi

# This form should run the entrypoint without overwriting the base entrypoint.
docker run -it --rm --network dind-network \
    -e DOCKER_TLS_CERTDIR=/certs \
    -v dind-certs-client:/certs/client:ro \
    -v "$(pwd)/data":/data \
    -v "$(pwd)/benchmarks":/benchmarks \
    openjdk-builder sh -c "./entrypoint.sh"
