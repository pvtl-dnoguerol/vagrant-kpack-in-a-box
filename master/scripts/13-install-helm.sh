#!/bin/bash

mkdir -p ~/workspace
cd ~/workspace

wget https://get.helm.sh/helm-v3.0.1-linux-amd64.tar.gz
tar xzvf helm-v3.0.1-linux-amd64.tar.gz
mv linux-amd64/helm /usr/local/bin
rm -rf linux-amd64
