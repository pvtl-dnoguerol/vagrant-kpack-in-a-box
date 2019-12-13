#!/bin/bash
set -e

IFNAME=$1
MASTER_ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
CLUSTER_NAME=local

mkdir -p ~/workspace
cd ~/workspace

## kube-proxy config file

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://${MASTER_ADDRESS}:6443 \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-credentials system:kube-proxy \
  --client-certificate=kube-proxy.crt \
  --client-key=kube-proxy.key \
  --embed-certs=true \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-proxy \
  --kubeconfig=kube-proxy.kubeconfig

kubectl config use-context ${CLUSTER_NAME} --kubeconfig=kube-proxy.kubeconfig

## kube-controller-manager config file

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-credentials system:kube-controller-manager \
  --client-certificate=kube-controller-manager.crt \
  --client-key=kube-controller-manager.key \
  --embed-certs=true \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-controller-manager \
  --kubeconfig=kube-controller-manager.kubeconfig

kubectl config use-context ${CLUSTER_NAME} --kubeconfig=kube-controller-manager.kubeconfig

## kube-scheduler config file

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-credentials system:kube-scheduler \
  --client-certificate=kube-scheduler.crt \
  --client-key=kube-scheduler.key \
  --embed-certs=true \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=system:kube-scheduler \
  --kubeconfig=kube-scheduler.kubeconfig

kubectl config use-context ${CLUSTER_NAME} --kubeconfig=kube-scheduler.kubeconfig

## admin config file

kubectl config set-cluster ${CLUSTER_NAME} \
  --certificate-authority=ca.crt \
  --embed-certs=true \
  --server=https://127.0.0.1:6443 \
  --kubeconfig=admin.kubeconfig

kubectl config set-credentials admin \
  --client-certificate=admin.crt \
  --client-key=admin.key \
  --embed-certs=true \
  --kubeconfig=admin.kubeconfig

kubectl config set-context ${CLUSTER_NAME} \
  --cluster=${CLUSTER_NAME} \
  --user=admin \
  --kubeconfig=admin.kubeconfig

kubectl config use-context ${CLUSTER_NAME} --kubeconfig=admin.kubeconfig

# Copy kube-proxy.kubeconfig to /tmp for worker nodes

cp kube-proxy.kubeconfig /tmp
chmod go+r /tmp/kube-proxy.kubeconfig
