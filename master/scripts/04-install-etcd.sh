#!/bin/bash
set -e

mkdir -p ~/workspace
cd ~/workspace

wget -q --https-only --timestamping \
  "https://github.com/coreos/etcd/releases/download/v3.3.9/etcd-v3.3.9-linux-amd64.tar.gz"

tar -xvf etcd-v3.3.9-linux-amd64.tar.gz

sudo mv etcd-v3.3.9-linux-amd64/etcd* /usr/local/bin/  

sudo mkdir -p /etc/etcd /var/lib/etcd

sudo cp ca.crt etcd-server.key etcd-server.crt /etc/etcd/

IFNAME=$1
ADDRESS="$(ip -4 addr show $IFNAME | grep "inet" | head -1 |awk '{print $2}' | cut -d/ -f1)"
ETCD_NAME=$(hostname -s)

cat <<EOF | sudo tee /etc/systemd/system/etcd.service
[Unit]
Description=etcd
Documentation=https://github.com/coreos

[Service]
ExecStart=/usr/local/bin/etcd \\
  --name ${ETCD_NAME} \\
  --cert-file=/etc/etcd/etcd-server.crt \\
  --key-file=/etc/etcd/etcd-server.key \\
  --peer-cert-file=/etc/etcd/etcd-server.crt \\
  --peer-key-file=/etc/etcd/etcd-server.key \\
  --trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-trusted-ca-file=/etc/etcd/ca.crt \\
  --peer-client-cert-auth \\
  --client-cert-auth \\
  --initial-advertise-peer-urls https://${ADDRESS}:2380 \\
  --listen-peer-urls https://${ADDRESS}:2380 \\
  --listen-client-urls https://${ADDRESS}:2379,https://127.0.0.1:2379 \\
  --advertise-client-urls https://${ADDRESS}:2379 \\
  --initial-cluster-token etcd-cluster-0 \\
  --initial-cluster master=https://${ADDRESS}:2380 \\
  --initial-cluster-state new \\
  --data-dir=/var/lib/etcd
Restart=on-failure
RestartSec=5

[Install]
WantedBy=multi-user.target
EOF

sudo systemctl daemon-reload
sudo systemctl enable etcd
sudo systemctl start etcd
