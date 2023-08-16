#!/usr/bin/env bash

set -euo pipefail

ROOT=$(git rev-parse --show-toplevel)

# Wait for the Kubernetes API server to be reachable.
while ! kubectl get namespace > /dev/null 2>&1;
do
  sleep 10
done

# Install Cert-Manager CRDs
kubectl apply -f https://github.com/cert-manager/cert-manager/releases/download/v1.12.0/cert-manager.crds.yaml

# Wait for the Cert-Manager CRDs to be available.
kubectl wait --for condition=established --timeout=60s crd/issuers.cert-manager.io
if [ $? -ne 0 ]; then
  echo "Cert-Manager CRDs are not available. Check Cert-Manager CRD installation."
  exit 1
fi

# Configure cilium CA issuer
./scripts/ca-certs.sh up
kubectl -n kube-system create secret tls cilium-ca \
  --dry-run=client \
  --cert=cilium-ca-crt.pem \
  --key=cilium-ca-key.pem \
  -o yaml | \
kubectl apply --server-side=true --force-conflicts -f -
echo "
apiVersion: cert-manager.io/v1
kind: Issuer
metadata:
  name: cilium
  namespace: kube-system
spec:
  ca:
    secretName: cilium-ca
" | kubectl apply -f-

# Install Prometheus CRDs
kubectl apply -f https://github.com/prometheus-operator/prometheus-operator/releases/download/v0.66.0/stripped-down-crds.yaml

# Wait for the Prometheus CRDs to be available.
kubectl wait --for condition=established --timeout=60s crd/servicemonitors.monitoring.coreos.com
if [ $? -ne 0 ]; then
  echo "Cert-Manager CRDs are not available. Check Cert-Manager CRD installation."
  exit 1
fi

# Install GatewayAPI CRDs
# More details: https://docs.cilium.io/en/stable/network/servicemesh/gateway-api/gateway-api/#prerequisites
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_gatewayclasses.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_gateways.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_httproutes.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/standard/gateway.networking.k8s.io_referencegrants.yaml
kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/gateway-api/v0.7.0/config/crd/experimental/gateway.networking.k8s.io_tlsroutes.yaml

# Wait for the GatewayAPI CRDs to be available.
kubectl wait --for condition=established --timeout=60s crd/gateways.gateway.networking.k8s.io
if [ $? -ne 0 ]; then
  echo "GatewayAPI CRDs are not available. Check GatewayAPI CRD installation."
  exit 1
fi