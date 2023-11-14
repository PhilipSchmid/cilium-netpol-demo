#!/bin/bash
CILIUM_NAMESPACE=kube-system

# Change policy enforcement for hosts to audit before applying the host policies:
for NODE_NAME in $(kubectl get nodes --no-headers=true | awk '{print $1}')
do
    CILIUM_POD_NAME=$(kubectl -n $CILIUM_NAMESPACE get pods -l "k8s-app=cilium" -o jsonpath="{.items[?(@.spec.nodeName=='$NODE_NAME')].metadata.name}")
    HOST_EP_ID=$(kubectl -n $CILIUM_NAMESPACE exec $CILIUM_POD_NAME -c cilium-agent -- cilium endpoint list -o jsonpath='{[?(@.status.identity.id==1)].id}')
    kubectl -n $CILIUM_NAMESPACE exec $CILIUM_POD_NAME -c cilium-agent -- cilium endpoint config $HOST_EP_ID PolicyAuditMode=Enabled
done