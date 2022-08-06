#!/bin/bash

set -eu

LOCAL_IP_ADDR=$(ip addr | grep inet | awk 'NR==2{ print $2; }' | head -c -4)
sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" ./openjdk-images-case-study/facts.Modusfile
fd 'Dockerfile$' ./docker-library-openjdk | xargs -I % sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" %
# Remove the sha256sum check, since we're not using the original binaries.
fd 'Dockerfile$' ./docker-library-openjdk | xargs -I % sed -i "/sha256sum/d" %
echo 1234 | nginx || true
export DOCKER_BUILDKIT=1

echo "Build images or print code size?"
MAIN_CHOICE=$(gum choose 'Build images (approx >1m)' 'Print code size (approx <1s)')
if [[ "$MAIN_CHOICE" == *'Print code size'* ]]; then
    ./code_size.sh openjdk-images-case-study/linux.Modusfile
    exit
fi

echo "Choose which benchmarks to run. (One or more.)"
BENCHMARK_CHOICE=$(gum choose 'Modus (approx 143.1s)' \
    'DOBS Sequential (approx 516.3s)' \
    'DOBS Parallel (approx 119.8s)' \
    'Docker Hub Evaluation (approx 826s)' \
    --no-limit)

echo "How many runs of each? Enter a positive integer."
NUM_RUNS=$(gum input --placeholder=10 --prompt="n = ")

if [ "$NUM_RUNS" == "" ]
then
    NUM_RUNS=10
fi

if [[ "$BENCHMARK_CHOICE" == *'Modus'* ]]; then
    touch benchmarks/modus-time.log
fi
if [[ "$BENCHMARK_CHOICE" == *'DOBS Sequential'* ]]; then
    touch benchmarks/official.log
fi
if [[ "$BENCHMARK_CHOICE" == *'DOBS Parallel'* ]]; then
    touch benchmarks/official-parallel.log
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

if [[ "$BENCHMARK_CHOICE" == *'Docker Hub Evaluation'* ]]; then
    cd docker-hub-eval && ./run-all-and-log.sh "$NUM_RUNS" && cd ..
fi

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
if [[ "$BENCHMARK_CHOICE" == *'Docker Hub Evaluation'* ]]; then
    cd docker-hub-eval && ./parse_runlog.py > ../benchmarks/docker-hub-eval-runlog.txt && cd ..
    cat benchmarks/docker-hub-eval-runlog.txt
fi
