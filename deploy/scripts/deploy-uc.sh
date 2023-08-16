#!/bin/bash

set -euo pipefail

echo "Wait 10 seconds to wait for kubeconfig to be available."
sleep 10

# Install AWS EBS CSI Driver
helm repo add aws-ebs-csi-driver https://kubernetes-sigs.github.io/aws-ebs-csi-driver
helm repo update aws-ebs-csi-driver
cat <<EOF | helm upgrade -i aws-ebs-csi-driver aws-ebs-csi-driver/aws-ebs-csi-driver --namespace kube-system --version 2.21.0 -f /dev/stdin
controller:
  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-role.kubernetes.io/infra
            operator: Exists
  tolerations:
    - key: CriticalAddonsOnly
      operator: Exists
    - effect: NoExecute
      operator: Exists
      tolerationSeconds: 300
    - key: node-role.kubernetes.io/infra
      operator: Exists
  extraVolumeTags:
    owner: "$OWNER"
    expiry: "$EXPIRY"
  enableMetrics: true
  k8sTagClusterId: "$CLUSTER_NAME"
  volumeModificationFeature:
    enabled: true
storageClasses:
- name: ebs-sc
  allowVolumeExpansion: true
  annotations:
    storageclass.kubernetes.io/is-default-class: "true"
EOF

# Install Cert-Manager
helm repo add jetstack https://charts.jetstack.io
helm repo update jetstack
helm upgrade -i cert-manager jetstack/cert-manager \
  -f ./scripts/values/cert-manager-values.yaml \
  --create-namespace \
  --skip-crds \
  -n cert-manager \
  --version v1.12.2

# Add Let's Encrypt cluster issuer
echo "
apiVersion: cert-manager.io/v1
kind: ClusterIssuer
metadata:
  name: letsencrypt-prod
spec:
  acme:
    email: cute@isovalent.com
    server: https://acme-v02.api.letsencrypt.org/directory
    privateKeySecretRef:
      name: lets-encrypt-clusterissuer-prod
    solvers:
    - http01:
        ingress:
          ingressClassName: nginx" | kubectl apply -f-

# Install Grafana
helm repo add grafana https://grafana.github.io/helm-charts
helm repo update grafana
cat <<EOF | helm upgrade -i grafana grafana/grafana --create-namespace -n monitoring --version 6.57.4 -f ./scripts/values/grafana-values.yaml -f /dev/stdin
adminPassword: $GRAFANA_ADMIN_PASSWORD
ingress:
  enabled: true
  annotations:
    cert-manager.io/cluster-issuer: $CLUSTERISSUER_NAME
  ingressClassName: nginx
  hosts:
  - $GRAFANA_URL
  tls:
  - secretName: grafana-tls
    hosts:
    - $GRAFANA_URL
EOF

# Install Prometheus Operator
# https://github.com/prometheus-community/helm-charts/tree/main/charts/kube-prometheus-stack
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update prometheus-community
cat <<EOF | helm upgrade -i kube-prometheus-stack prometheus-community/kube-prometheus-stack --skip-crds --create-namespace -n monitoring --version 47.3.0 -f ./scripts/values/prometheus-values.yaml -f /dev/stdin
# We only deploy a single Prometheus. This one should therefore watch for all CRs.
prometheus:
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      cert-manager.io/cluster-issuer: $CLUSTERISSUER_NAME
    hosts:
    - $PROMETHEUS_URL
    tls:
    - secretName: prometheus-tls
      hosts:
      - $PROMETHEUS_URL
  prometheusSpec:
    ruleSelectorNilUsesHelmValues: false
    serviceMonitorSelectorNilUsesHelmValues: false
    podMonitorSelectorNilUsesHelmValues: false
    probeSelectorNilUsesHelmValues: false
    scrapeConfigSelectorNilUsesHelmValues: false
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: node-role.kubernetes.io/infra
              operator: Exists
    tolerations:
    - key: node-role.kubernetes.io/infra
      operator: Exists
      effect: NoSchedule
alertmanager:
  ingress:
    enabled: true
    ingressClassName: nginx
    annotations:
      cert-manager.io/cluster-issuer: $CLUSTERISSUER_NAME
    hosts:
    - $ALERTMANAGER_URL
    tls:
    - secretName: alertmanager-tls
      hosts:
      - $ALERTMANAGER_URL
  alertmanagerSpec:
    affinity:
      nodeAffinity:
        requiredDuringSchedulingIgnoredDuringExecution:
          nodeSelectorTerms:
          - matchExpressions:
            - key: node-role.kubernetes.io/infra
              operator: Exists
    tolerations:
    - key: node-role.kubernetes.io/infra
      operator: Exists
      effect: NoSchedule
EOF

# Install Metrics Server
helm repo add metrics-server https://kubernetes-sigs.github.io/metrics-server/
helm repo update metrics-server
helm upgrade -i metrics-server metrics-server/metrics-server \
  -f ./scripts/values/metrics-server-values.yaml \
  --create-namespace \
  -n monitoring \
  --version 3.10.0

# Install Nginx Ingress Controller
helm repo add ingress-nginx https://kubernetes.github.io/ingress-nginx
helm repo update ingress-nginx
# Let's simply run Ingress Nginx in hostNetwork because that's the easiest to afterward pointing the generic infra LB to the regarding infra nodes and ports.
cat <<EOF | helm upgrade -i ingress-nginx ingress-nginx/ingress-nginx --create-namespace -n ingress-nginx --version 4.7.1 -f /dev/stdin
controller:
  ingressClassResource:
    name: nginx
    enabled: true
    default: true
    controllerValue: "k8s.io/ingress-nginx"
  ingressClass: nginx
  watchIngressWithoutClass: true

  hostNetwork: true
  kind: "DaemonSet"

  tolerations:
  - key: node-role.kubernetes.io/infra
    operator: Exists
    effect: NoSchedule

  affinity:
    nodeAffinity:
      requiredDuringSchedulingIgnoredDuringExecution:
        nodeSelectorTerms:
        - matchExpressions:
          - key: node-role.kubernetes.io/infra
            operator: Exists
    podAntiAffinity:
      preferredDuringSchedulingIgnoredDuringExecution:
      - weight: 100
        podAffinityTerm:
          labelSelector:
            matchExpressions:
            - key: app.kubernetes.io/name
              operator: In
              values:
              - ingress-nginx
            - key: app.kubernetes.io/instance
              operator: In
              values:
              - ingress-nginx
            - key: app.kubernetes.io/component
              operator: In
              values:
              - controller
          topologyKey: kubernetes.io/hostname

  service:
    type: ClusterIP

  metrics:
    enabled: true
    serviceMonitor:
      enabled: true

  serviceAccount:
    create: true

  admissionWebhooks:
    enabled: false
EOF

# Deploy Star Wars demo:
kubectl apply $(ls ./manifests/start-wars-demo/* | awk ' { print " -f " $1 } ')

# Deploy Goldpinger:
kubectl apply $(ls ./manifests/goldpinger/* | awk ' { print " -f " $1 } ')
echo "---
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: goldpinger
  namespace: goldpinger
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
spec:
  rules:
  - host: $GOLDPINGER_URL
    http:
      paths:
      - pathType: Prefix
        path: /
        backend:
          service:
            name: goldpinger
            port:
              number: 8080
  tls:
  - hosts:
    - $GOLDPINGER_URL
    secretName: goldpinger-tls" | kubectl apply -f-
