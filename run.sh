#!/usr/bin/env bash

set -eux

docker build . -t openjdk-builder

docker network create dind-network
docker volume create dind-certs-ca
docker volume create dind-certs-client

docker run --privileged --name dind-docker -d \
    --network dind-network --network-alias docker \
    -e DOCKER_TLS_CERTDIR=/certs \
    -v dind-certs-ca:/certs/ca \
    -v dind-certs-client:/certs/client \
    docker:dind

docker run --rm --network dind-network \
	-e DOCKER_TLS_CERTDIR=/certs \
	-v dind-certs-client:/certs/client:ro \
	openjdk-builder
