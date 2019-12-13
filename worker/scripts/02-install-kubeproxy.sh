#!/bin/bash
mkdir -p ~/workspace
cd ~/workspace

MASTER_ADDRESS=$1
IFNAME=$2
BASE_IP="$(echo $MASTER_ADDRESS | cut -d "." -f1-3)"
CIDR_NETWORK="$(sipcalc $IFNAME -i | grep 'Network address' | awk -F- '{print $2}' | sed 's/ //')"
CIDR_MASK="$(sipcalc $IFNAME -i | grep -m 1 'Network mask (bits)' | awk -F- '{print $2}' | sed 's/ //')"
CIDR="$CIDR_NETWORK/$CIDR_MASK"

scp -o "StrictHostKeyChecking no" -i /home/vagrant/.ssh/id_rsa vagrant@$MASTER_ADDRESS:/tmp/kube-proxy.kubeconfig /var/lib/kube-proxy/kubeconfig

cat <<EOF | sudo tee /var/lib/kube-proxy/kube-proxy-config.yaml
kind: KubeProxyConfiguration
apiVersion: kubeproxy.config.k8s.io/v1alpha1
clientConnection:
  kubeconfig: "/var/lib/kube-proxy/kubeconfig"
mode: "iptables"
clusterCIDR: "10.200.0.0/16"
EOF

cat <<EOF | sudo tee /etc/systemd/system/kube-proxy.service
[Unit]
Description=Kubernetes Kube Proxy
Documentation=https://github.com/kubernetes/kubernetes

[Service]
ExecStart=/usr/local/bin/kube-proxy \\
  --config=/var/lib/kube-proxy/kube-proxy-config.yaml
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable kube-proxy
systemctl start kube-proxy
