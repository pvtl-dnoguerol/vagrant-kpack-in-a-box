#!/bin/bash

mkdir -p ~/workspace
cd ~/workspace

cat > /tmp/approve-csr.sh << EOF
#!/bin/bash
# this is a hack - the executed script should really check for the presence of the
# pending cert before returning
sleep 30
# approve the cert
kubectl get csr | grep Pending | awk '{system("kubectl certificate approve "\$1)}'
EOF

chmod +x /tmp/approve-csr.sh
