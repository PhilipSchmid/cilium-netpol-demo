#!/bin/bash
CILIUM_NAMESPACE=kube-system

# Print PolicyAuditMode for hosts:
for NODE_NAME in $(kubectl get nodes --no-headers=true | awk '{print $1}')
do
    CILIUM_POD_NAME=$(kubectl -n $CILIUM_NAMESPACE get pods -l "k8s-app=cilium" -o jsonpath="{.items[?(@.spec.nodeName=='$NODE_NAME')].metadata.name}")
    HOST_EP_ID=$(kubectl -n $CILIUM_NAMESPACE exec $CILIUM_POD_NAME -c cilium-agent -- cilium endpoint list -o jsonpath='{[?(@.status.identity.id==1)].id}')
    echo "$NODE_NAME ($CILIUM_POD_NAME): PolicyAuditMode for host ($HOST_EP_ID): $(kubectl -n $CILIUM_NAMESPACE exec $CILIUM_POD_NAME -c cilium-agent -- cilium endpoint get $HOST_EP_ID -o jsonpath='{$[0].status.realized.options.PolicyAuditMode}')"
done