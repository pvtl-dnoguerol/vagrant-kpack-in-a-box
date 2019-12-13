#!/bin/bash
set -e

mkdir -p ~/workspace
cd ~/workspace

IFNAME=$1
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
CLUSTER_NAME=local

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://${ADDRESS}:6443

kubectl config set-credentials admin \
  --client-certificate=admin.crt \
  --client-key=admin.key

kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=admin

kubectl config use-context ${CLUSTER_NAME}
