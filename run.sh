#!/usr/bin/env bash

set -eux

docker build . -t openjdk-builder

docker network create dind-network || true
docker volume create dind-certs-ca || true
docker volume create dind-certs-client || true

CONTAINER_ID=$(
    docker run --privileged --name dind-docker -d \
        --network dind-network --network-alias docker \
        -e DOCKER_TLS_CERTDIR=/certs \
        -v dind-certs-ca:/certs/ca \
        -v dind-certs-client:/certs/client \
        docker:dind --registry-mirror=http://localhost:5000
            )

docker exec -it "$CONTAINER_ID" sh -c "docker run -d -p 5000:5000 -e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io --restart=always --name registry registry:2"

# should prob start then exec our entrypoint
docker run -it --rm --network dind-network \
    -e DOCKER_TLS_CERTDIR=/certs \
    -v dind-certs-client:/certs/client:ro \
    openjdk-builder sh
