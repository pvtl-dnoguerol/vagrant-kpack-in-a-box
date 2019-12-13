#!/bin/bash
mkdir -p ~/workspace
cd ~/workspace

MASTER_ADDRESS=$1

# execute the remote script
ssh -o "StrictHostKeyChecking no" -i /home/vagrant/.ssh/id_rsa vagrant@$MASTER_ADDRESS '/tmp/approve-csr.sh'
