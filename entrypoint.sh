#!/bin/sh

LOCAL_IP_ADDR=$(ip addr | grep inet | awk 'NR==2{ print $2; }' | head -c -4)
sed -i "s/https:\/\/download.java.net/http:\/\/$LOCAL_IP_ADDR/g" facts.Modusfile
echo 1234 | nginx
sh
