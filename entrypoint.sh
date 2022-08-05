#!/bin/bash

set -eu

LOCAL_IP_ADDR=$(ip addr | grep inet | awk 'NR==2{ print $2; }' | head -c -4)
sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" ./openjdk-images-case-study/facts.Modusfile
fd 'Dockerfile$' ./docker-library-openjdk | xargs -I % sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" %
# Remove the sha256sum check, since we're not using the original binaries.
fd 'Dockerfile$' ./docker-library-openjdk | xargs -I % sed -i "/sha256sum/d" %
echo 1234 | nginx || true
mkdir -p benchmarks
export DOCKER_BUILDKIT=1

echo "Choose which benchmarks to run. (One or more.)"
BENCHMARK_CHOICE=$(gum choose 'Modus (approx 143.1s)' 'DOBS Sequential (approx 516.3s)' 'DOBS Parallel (approx 119.8s)' --no-limit)

echo "How many runs of each? Enter a positive integer."
NUM_RUNS=$(gum input --placeholder=10 --prompt="n = ")

if [ "$NUM_RUNS" == "" ]
then
    NUM_RUNS=10
fi

for ((i = 1; i <= "$NUM_RUNS"; i++))
do
    if [[ "$BENCHMARK_CHOICE" == *'Modus'* ]]; then
        docker builder prune -a -f && docker image prune -a -f;
        /usr/bin/time -o benchmarks/modus-time.log -a -p modus build ./openjdk-images-case-study 'openjdk(A, B, C)' -f <(cat ./openjdk-images-case-study/*.Modusfile) \
            --output-profiling="benchmarks/modus_profile_$i.log";
    fi

    if [[ "$BENCHMARK_CHOICE" == *'DOBS Sequential'* ]]; then
        docker builder prune -a -f && docker image prune -a -f;
        fd 'Dockerfile$' ./docker-library-openjdk | grep -v windows | /usr/bin/time -o benchmarks/official.log -a -p xargs -I % sh -c 'docker build ./docker-library-openjdk -f %';
    fi


    if [[ "$BENCHMARK_CHOICE" == *'DOBS Parallel'* ]]; then
        docker builder prune -a -f && docker image prune -a -f;
        fd 'Dockerfile$' ./docker-library-openjdk | grep -v windows | /usr/bin/time -o benchmarks/official-parallel.log -a -p parallel --will-cite docker build ./docker-library-openjdk -f {};
    fi
done

if [[ "$BENCHMARK_CHOICE" == *'Modus'* ]]; then
    echo 'Modus'
    grep real benchmarks/modus-time.log | datamash mean 2 -W
fi
if [[ "$BENCHMARK_CHOICE" == *'DOBS Sequential'* ]]; then
    echo 'Official (Sequential)'
    grep real benchmarks/official.log | datamash mean 2 -W
fi
if [[ "$BENCHMARK_CHOICE" == *'DOBS Parallel'* ]]; then
    echo 'Official (Parallel)'
    grep real benchmarks/official-parallel.log | datamash mean 2 -W
fi
