#!/bin/bash

set -eux

LOCAL_IP_ADDR=$(ip addr | grep inet | awk 'NR==2{ print $2; }' | head -c -4)
sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" facts.Modusfile
echo 1234 | nginx

for ((i = 1; i <= $1; i++))
do
    docker builder prune -a -f && docker image prune -a -f;
    /usr/bin/time -o modus-time.log -a -p modus build . 'openjdk(A, B, C)' -f <(cat ./*.Modusfile) \
        --output-profiling="modus_profile_$i.log";
done
grep real modus-time.log | datamash mean 2 -W
