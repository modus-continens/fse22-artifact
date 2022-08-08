#!/bin/bash

function openjdkBuildImages() {
    echo "How many runs of the build? One run is about 780s."
    NUM_RUNS=$(gum input --placeholder=10 --prompt="n = ")
    if [ "$NUM_RUNS" == "" ]
    then
        NUM_RUNS=10
    fi

    echo "First, computing mean template processing time:"
    cd docker-library-openjdk
    truncate -s 0 ../benchmarks/dobs-template-time.log
    for ((i = 1; i <= 10; i++))
    do
        /usr/bin/time -o ../benchmarks/dobs-template-time.log -a -p ./apply-templates.sh
    done
    MEAN_TEMPLATE=$(grep real ../benchmarks/dobs-template-time.log | datamash mean 2 -W)
    cd ..

    truncate -s 0 benchmarks/modus-time.log
    truncate -s 0 benchmarks/official.log
    truncate -s 0 benchmarks/official-parallel.log
    for ((i = 1; i <= "$NUM_RUNS"; i++))
    do
        docker builder prune -a -f && docker image prune -a -f;
        /usr/bin/time -o benchmarks/modus-time.log -a -p modus build ./openjdk-images-case-study 'openjdk(A, B, C)' -f <(cat ./openjdk-images-case-study/*.Modusfile) \
            --output-profiling="benchmarks/modus_profile_$i.log";

        docker builder prune -a -f && docker image prune -a -f;
        fd 'Dockerfile$' ./docker-library-openjdk | grep -v windows | /usr/bin/time -o benchmarks/official.log -a -p xargs -I % sh -c 'docker build ./docker-library-openjdk -f %';


        docker builder prune -a -f && docker image prune -a -f;
        fd 'Dockerfile$' ./docker-library-openjdk | grep -v windows | /usr/bin/time -o benchmarks/official-parallel.log -a -p parallel --halt now,fail=1 --will-cite docker build ./docker-library-openjdk -f {};
    done

    truncate -s 0 benchmarks/buildTime.csv
    DOBS_SEQUENTIAL_MEAN=$(grep real benchmarks/official.log | datamash mean 2 -W)
    DOBS_PARALLEL_MEAN=$(grep real benchmarks/official-parallel.log | datamash mean 2 -W)
    MODUS_MEAN=$(grep real benchmarks/modus-time.log | datamash mean 2 -W)
    {
        echo "Approach,Mean (s),Mean including Templating (s)";
        echo "DOBS Sequential,$DOBS_SEQUENTIAL_MEAN,$(echo "$DOBS_SEQUENTIAL_MEAN" + "$MEAN_TEMPLATE" | bc)";
        echo "DOBS Parallel,$DOBS_PARALLEL_MEAN,$(echo "$DOBS_PARALLEL_MEAN" + "$MEAN_TEMPLATE" | bc)";
        echo "Modus,$MODUS_MEAN,$MODUS_MEAN"; # Modus doesn't use templating
    } > benchmarks/buildTime.csv
    cat benchmarks/buildTime.csv
}

function openjdkCodeSize() {
    ./code_size.sh docker-library-openjdk/Dockerfile-linux.template > benchmarks/DOBS-template-size
    ./code_size.sh docker-library-openjdk/apply-templates.sh > benchmarks/apply-templates-size
    ./code_size.sh docker-library-openjdk/jq-template.awk > benchmarks/jq-awk-size
    truncate -s 0 benchmarks/DOBS-code-size
    for line in "1p" "2p" "3p"
    do
        cat <(sed -n "$line" benchmarks/DOBS-template-size) <(sed -n "$line" benchmarks/apply-templates-size) <(sed -n "$line" benchmarks/jq-awk-size) | datamash sum 1,2,3 -W >> benchmarks/DOBS-code-size
    done

    ./code_size.sh openjdk-images-case-study/linux.Modusfile > benchmarks/modus-code-size

    echo "DOBS:"
    cat benchmarks/DOBS-code-size
    echo "Modus:"
    cat benchmarks/modus-code-size
}

function dockerHubEval() {
    echo "How many runs of the experiment? One run is about 832s."
    NUM_RUNS=$(gum input --placeholder=10 --prompt="n = ")
    if [ "$NUM_RUNS" == "" ]
    then
        NUM_RUNS=10
    fi

    cd docker-hub-eval && ./run-all-and-log.sh "$NUM_RUNS" && cd ..
    echo 'Docker Hub Evaluation:'
    cd docker-hub-eval && ./parse_runlog.py > ../benchmarks/docker-hub-eval-runlog.txt && cd ..
    cat benchmarks/docker-hub-eval-runlog.txt
}

set -euo pipefail

LOCAL_IP_ADDR=$(ip addr | grep inet | awk 'NR==2{ print $2; }' | head -c -4)
sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" ./openjdk-images-case-study/facts.Modusfile
fd 'Dockerfile$' ./docker-library-openjdk | xargs -I % sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" %
# Remove the sha256sum check, since we're not using the original binaries.
fd 'Dockerfile$' ./docker-library-openjdk | xargs -I % sed -i "/sha256sum/d" %
echo 1234 | nginx || true
export DOCKER_BUILDKIT=1

echo "Choose:"
MAIN_CHOICE=$(gum choose 'OpenJDK - Build Images' 'OpenJDK - Code Size' 'Docker Hub Evaluation')

if [[ "$MAIN_CHOICE" == *'OpenJDK - Build Images'* ]]; then
    openjdkBuildImages
    exit
fi

if [[ "$MAIN_CHOICE" == *'OpenJDK - Code Size'* ]]; then
    openjdkCodeSize
    exit
fi

if [[ "$MAIN_CHOICE" == *'Docker Hub Evaluation'* ]]; then
    dockerHubEval
    exit
fi
