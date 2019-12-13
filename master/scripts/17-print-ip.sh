#!/bin/bash

mkdir -p ~/workspace
cd ~/workspace

IFNAME=$1
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"

echo "******************************************"
echo "Master node IP address is: $ADDRESS"
echo "******************************************"
