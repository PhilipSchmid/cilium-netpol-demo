#!/bin/bash
CILIUM_NAMESPACE=kube-system

# Let's use Cilium's internal Hubble CLI to check for recent AUDIT|DROPPED events:
for NODE_NAME in $(kubectl get nodes --no-headers=true | awk '{print $1}')
do
    CILIUM_POD_NAME=$(kubectl -n $CILIUM_NAMESPACE get pods -l "k8s-app=cilium" -o jsonpath="{.items[?(@.spec.nodeName=='$NODE_NAME')].metadata.name}")
    # Output all connections (allowed & audited)
    kubectl -n $CILIUM_NAMESPACE exec $CILIUM_POD_NAME -c cilium-agent -- hubble observe -t policy-verdict --identity 1 --verdict AUDIT --verdict DROPPED
done