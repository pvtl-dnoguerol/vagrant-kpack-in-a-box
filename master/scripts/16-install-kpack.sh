#!/bin/bash

mkdir -p ~/workspace
cd ~/workspace

cat > kpack-release-0.0.5.yaml << EOF
apiVersion: v1
kind: Namespace
metadata:
  name: kpack
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: builds.build.pivotal.io
spec:
  group: build.pivotal.io
  version: v1alpha1
  names:
    kind: Build
    singular: build
    plural: builds
    shortNames:
    - cnbbuild
    - cnbbuilds
    - bld
    categories:
    - kpack
  scope: Namespaced
  subresources:
    status: {}
  additionalPrinterColumns:
  - name: Image
    type: string
    JSONPath: .status.latestImage
  - name: Succeeded
    type: string
    JSONPath: .status.conditions[?(@.type=="Succeeded")].status
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: builders.build.pivotal.io
spec:
  group: build.pivotal.io
  version: v1alpha1
  names:
    kind: Builder
    singular: builder
    plural: builders
    shortNames:
    - cnbbuilder
    - cnbbuilders
    - bldr
    categories:
    - kpack
  scope: Namespaced
  subresources:
    status: {}
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: clusterbuilders.build.pivotal.io
spec:
  group: build.pivotal.io
  version: v1alpha1
  names:
    kind: ClusterBuilder
    singular: clusterbuilder
    plural: clusterbuilders
    shortNames:
    - clstbldr
    categories:
    - kpack
  scope: Cluster
  subresources:
    status: {}
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kpack-controller-admin
rules:
- apiGroups:
  - build.pivotal.io
  resources:
  - builds
  - builds/status
  - images
  - images/status
  - builders
  - builders/status
  - clusterbuilders
  - clusterbuilders/status
  - sourceresolvers
  - sourceresolvers/status
  verbs:
  - get
  - list
  - create
  - update
  - delete
  - patch
  - watch
- apiGroups:
  - ""
  resources:
  - secrets
  - serviceaccounts
  verbs:
  - get
- apiGroups:
  - ""
  resources:
  - persistentvolumeclaims
  - pods
  verbs:
  - get
  - list
  - create
  - update
  - delete
  - watch
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRole
metadata:
  name: kpack-webhook-admin
rules:
- apiGroups:
  - ""
  resources:
  - secrets
  verbs:
  - get
  - create
  - update
- apiGroups:
  - apps
  resources:
  - deployments
  verbs:
  - get
- apiGroups:
  - admissionregistration.k8s.io
  resources:
  - mutatingwebhookconfigurations
  verbs:
  - get
  - create
  - update
  - delete
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kpack-controller-admin
subjects:
- kind: ServiceAccount
  name: controller
  namespace: kpack
roleRef:
  kind: ClusterRole
  name: kpack-controller-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: rbac.authorization.k8s.io/v1
kind: ClusterRoleBinding
metadata:
  name: kpack-webhook-admin
subjects:
- kind: ServiceAccount
  name: webhook
  namespace: kpack
roleRef:
  kind: ClusterRole
  name: kpack-webhook-admin
  apiGroup: rbac.authorization.k8s.io
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kpack-controller
  namespace: kpack
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kpack-controller
  template:
    metadata:
      labels:
        app: kpack-controller
        version: 0.0.5-rc.32
    spec:
      serviceAccountName: controller
      containers:
      - name: controller
        image: gcr.io/cf-build-service-public/kpack/controller@sha256:335aca7af7fbc73d13439c607988118686930556c1d2994306ef27d62940a941
        env:
        - name: BUILD_INIT_IMAGE
          value: gcr.io/cf-build-service-public/kpack/build-init@sha256:945597c7dd674b4cbcea489b4ebc47cea12c7cea97cee9a6dbd7ab6b38c125af
        - name: REBASE_IMAGE
          value: gcr.io/cf-build-service-public/kpack/rebase@sha256:c33bdfc50fb5883b6358588c6a0baf8291006329ac7d8ece2622d0a0b3bcd6b4
        - name: COMPLETION_IMAGE
          value: gcr.io/cf-build-service-public/kpack/completion@sha256:1947978867112073ea274ee789f7bf8bbe6d80c8b8a30a3b0b644c506e9d2962
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: images.build.pivotal.io
spec:
  group: build.pivotal.io
  version: v1alpha1
  names:
    kind: Image
    singular: image
    plural: images
    shortNames:
    - cnbimage
    - cnbimages
    categories:
    - kpack
  scope: Namespaced
  subresources:
    status: {}
  additionalPrinterColumns:
  - name: LatestImage
    type: string
    JSONPath: .status.latestImage
  - name: Ready
    type: string
    JSONPath: .status.conditions[?(@.type=="Ready")].status
---
apiVersion: v1
kind: Service
metadata:
  name: kpack-webhook
  namespace: kpack
spec:
  ports:
  - port: 443
    targetPort: 8443
  selector:
    role: webhook
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: controller
  namespace: kpack
---
apiVersion: v1
kind: ServiceAccount
metadata:
  name: webhook
  namespace: kpack
---
apiVersion: apiextensions.k8s.io/v1beta1
kind: CustomResourceDefinition
metadata:
  name: sourceresolvers.build.pivotal.io
spec:
  group: build.pivotal.io
  version: v1alpha1
  names:
    kind: SourceResolver
    singular: sourceresolver
    plural: sourceresolvers
    categories:
    - kpack
  scope: Namespaced
  subresources:
    status: {}
---
apiVersion: apps/v1
kind: Deployment
metadata:
  name: kpack-webhook
  namespace: kpack
spec:
  replicas: 1
  selector:
    matchLabels:
      app: kpack-webhook
  template:
    metadata:
      labels:
        app: kpack-webhook
        role: webhook
        version: 0.0.5-rc.32
    spec:
      serviceAccountName: webhook
      containers:
      - name: webhook
        image: gcr.io/cf-build-service-public/kpack/webhook@sha256:ce154e4bb0ed26aeb02c910a4f37dc41ff7538794465533c83adcb0f110d96fe
        env:
        - name: SYSTEM_NAMESPACE
          valueFrom:
            fieldRef:
              fieldPath: metadata.namespace
EOF

kubectl apply -f kpack-release-0.0.5.yaml
