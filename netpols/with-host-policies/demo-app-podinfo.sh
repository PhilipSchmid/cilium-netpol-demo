#!/bin/bash
#
# https://github.com/stefanprodan/podinfo/tree/master
#
helm repo add podinfo https://stefanprodan.github.io/podinfo
helm repo update podinfo

kubectl create namespace podinfo

# Deploy default CNP
echo "---
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: allow-within-namespace
  namespace: podinfo
spec:
  description: Allow NS internal traffic, block everything else
  endpointSelector: {}
  ingress:
  - fromEndpoints:
    - {}
  egress:
  - toEndpoints:
    - {}" | kubectl apply -f-

kubectl label namespace podinfo exposed=true
kubectl label namespace podinfo metrics=true

# Install the frontend
cat <<EOF | helm upgrade -i frontend --namespace podinfo podinfo/podinfo -f /dev/stdin
backend: http://backend-podinfo:9898/echo
replicaCount: 2
serviceMonitor:
  enabled: true
ingress:
  enabled: true
  className: nginx
  annotations:
    cert-manager.io/cluster-issuer: letsencrypt-prod
  hosts:
  - host: podinfo.philip-netpol-demo.cilium.rocks
    paths:
    - path: /
      pathType: ImplementationSpecific
  tls:
  - secretName: podinfo-frontend-tls
    hosts:
    - podinfo.philip-netpol-demo.cilium.rocks
EOF

# Install the backend
helm upgrade -i backend \
  --namespace podinfo \
  --set redis.enabled=true \
  podinfo/podinfo