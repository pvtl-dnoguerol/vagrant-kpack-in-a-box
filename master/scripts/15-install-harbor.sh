#!/bin/bash

mkdir -p ~/workspace
cd ~/workspace

HARBOR_DOMAIN=$1

kubectl create ns harbor

helm repo add harbor https://helm.goharbor.io
helm install harbor --namespace harbor --set persistence.enabled=false --set expose.ingress.hosts.core=core.$HARBOR_DOMAIN --set expose.ingress.hosts.notary=notary.$HARBOR_DOMAIN --set expose.tls.enabled=false --set externalURL=https://core.$HARBOR_DOMAIN harbor/harbor
