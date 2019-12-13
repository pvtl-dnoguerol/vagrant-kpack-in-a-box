#!/bin/bash

mkdir -p ~/workspace
cd ~/workspace

# Create ingress controller namespace
kubectl create ns ingress-controller

# Create TLS secret
dos2unix /home/vagrant/workspace/tls.crt
dos2unix /home/vagrant/workspace/tls.key
kubectl create secret tls ingress-tls-secret --cert=/home/vagrant/workspace/tls.crt --key=/home/vagrant/workspace/tls.key -n ingress-controller

# Create default backend for 404 responses
kubectl run ingress-default-backend --namespace=ingress-controller --image=gcr.io/google_containers/defaultbackend:1.0 --port=8080 --limits=cpu=10m,memory=20Mi --expose

# Create config map
kubectl --namespace=ingress-controller create configmap haproxy-ingress

cat > haproxy-ingress.yaml << EOF
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: ingress-controller
  namespace: ingress-controller
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRole
metadata:
  name: ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - endpoints
      - nodes
      - pods
      - secrets
    verbs:
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - nodes
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - services
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - "extensions"
    resources:
      - ingresses
    verbs:
      - get
      - list
      - watch
  - apiGroups:
      - ""
    resources:
      - events
    verbs:
      - create
      - patch
  - apiGroups:
      - "extensions"
    resources:
      - ingresses/status
    verbs:
      - update
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: Role
metadata:
  name: ingress-controller
  namespace: ingress-controller
rules:
  - apiGroups:
      - ""
    resources:
      - configmaps
      - pods
      - secrets
      - namespaces
    verbs:
      - get
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - get
      - update
  - apiGroups:
      - ""
    resources:
      - configmaps
    verbs:
      - create
  - apiGroups:
      - ""
    resources:
      - endpoints
    verbs:
      - get
      - create
      - update
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: ClusterRoleBinding
metadata:
  name: ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: ClusterRole
  name: ingress-controller
subjects:
  - kind: ServiceAccount
    name: ingress-controller
    namespace: ingress-controller
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: ingress-controller
---
apiVersion: rbac.authorization.k8s.io/v1beta1
kind: RoleBinding
metadata:
  name: ingress-controller
  namespace: ingress-controller
roleRef:
  apiGroup: rbac.authorization.k8s.io
  kind: Role
  name: ingress-controller
subjects:
  - kind: ServiceAccount
    name: ingress-controller
    namespace: ingress-controller
  - apiGroup: rbac.authorization.k8s.io
    kind: User
    name: ingress-controller
---    
# see https://kubernetes.io/docs/reference/workloads-18-19
apiVersion: apps/v1beta2
kind: Deployment
metadata:
  labels:
    run: haproxy-ingress
  name: haproxy-ingress
  namespace: ingress-controller
spec:
  selector:
    matchLabels:
      run: haproxy-ingress
  template:
    metadata:
      labels:
        run: haproxy-ingress
    spec:
      serviceAccountName: ingress-controller
      hostNetwork: true
      containers:
      - name: haproxy-ingress
        image: quay.io/jcmoraisjr/haproxy-ingress
        args:
        - --default-backend-service=\$(POD_NAMESPACE)/ingress-default-backend
        - --default-ssl-certificate=\$(POD_NAMESPACE)/ingress-tls-secret
        - --configmap=\$(POD_NAMESPACE)/haproxy-ingress
        ports:
        - name: http
          containerPort: 80
        - name: https
          containerPort: 443
        - name: stat
          containerPort: 1936
        livenessProbe:
          httpGet:
            path: /healthz
            port: 10253
        env:
        - name: POD_NAME
          valueFrom:
            fieldRef:
              fieldPath: metadata.name
        - name: POD_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
EOF

# Deploy ingress controller
kubectl create -f haproxy-ingress.yaml

# Expose ingress controller as NodePort
kubectl --namespace=ingress-controller expose deploy/haproxy-ingress --type=NodePort
