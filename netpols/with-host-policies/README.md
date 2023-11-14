# Demo Network Policies (with Host Policies)

## Generic Hubble Configuration for Visibility
```bash
# - Since we enabled TLS for Hubble, we need to configure Hubble CLI accordingly
# - Get Hubble CLI from here: https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#install-the-hubble-client
hubble config set tls true
hubble config set tls-ca-cert-files /path/to/cilium-netpol-demo/deploy/cilium-ca-crt.pem
hubble config set tls-server-name "*.hubble-relay.cilium.io"
# Open the port-forwarding in a separate shell:
kubectl port-forward -n kube-system svc/hubble-relay 4245:443
# Finally check Hubble CLI's connection and the flows:
hubble status
```

## Cilium Host Policies
```bash
# Activate audit mode safe guard before applying Cilium host policies
# IMPORTANT: This configuration change is only temporarily until the Cilium agent pods are restarted the next time! Ensure to fix all false positives or remove the Cilium host policies before restarting any Cilium agent pod or node!
./host-enforcement-to-audit.sh

# Check current enforcement status:
./host-enforcement-status.sh

# Apply Cilium host policies:
kubectl apply -f ccnp-host-cp.yaml -f ccnp-host-all.yaml -f ccnp-host-infra.yaml

# Wait a few minutes (Hubble flow cache) and then check if communications flows would be dropped if you weren't running in audit mode:
./host-enforcement-verification.sh

# In addition, check for flows from a cluster-wide perspective.
hubble observe -t policy-verdict -f --identity 1 --verdict AUDIT --verdict DROPPED

# If you don't see any relevant audit/dropped event, activate Cilium host policiy enforcement. HEADS-UP: Currently, there's a bug where the connections might get interrupted shortly (see https://github.com/cilium/cilium/issues/25448). A workaround to mitigate this would be to enable, disable, and reenable host policy enforcement.
./host-enforcement-to-enforce.sh
```

## Infrastructure Components
```bash
# Label namespaces with Ingress resources that should be reachable from Nginx ingress controller with `exposed=true`:
kubectl label namespace goldpinger exposed=true
kubectl label namespace monitoring exposed=true
kubectl label namespace kube-system exposed=true # Required for Hubble-UI. Move Hubble-UI to a dedicated namespaces for production: https://docs.cilium.io/en/stable/gettingstarted/hubble/#enable-the-hubble-ui ("Helm (Standalone install)" tab)

# Label namespaces with metric endpoints that should be scraped by Prometheus with `metrics=true`:
kubectl label namespace goldpinger metrics=true
kubectl label namespace kube-system metrics=true
kubectl label namespace ingress-nginx metrics=true

# Kube-system
kubectl apply -f cnp-infra-kube-system.yaml

# Nginx Ingress Controller
kubectl apply -f cnp-infra-ingress-nginx.yaml

# Cert-Manager
kubectl apply -f cnp-infra-cert-manager.yaml

# Kube Prometheus Stack
kubectl apply -f cnp-infra-monitoring-stack.yaml

# Goldpinger:
kubectl apply -f cnp-infra-goldpinger.yaml
```

## Cluster-wide Policies
The goal should be to deploy new user workload namespaces with only a very small set of default policies. Hence, you can leverage CiliumClusterwideNetworkPolicies (CCNPs) to predefine permits of common services like ingress or monitoring to communicate with the new namespace.

In addition, you can leverage CCNPs to enable Cilium's DNS visibility by applying an egress policy that uses `toPorts[*].rules.dns`.

```bash
kubectl apply -f ccnp-global-infra.yaml
```

## User Workload
As there are already CCNPs matching for everything `spec.endpointSelector: {}`, in both directions (`spec.ingress` and `spec.egress`), newly created (user) namespaces are already in a deny-all state. As a result, even namespace internal traffic is denied until a new `allow-within-namespace` CiliumNetworkPolicy (CNP) is created to allow this traffic:

```yaml
---
apiVersion: "cilium.io/v2"
kind: CiliumNetworkPolicy
metadata:
  name: allow-within-namespace
  namespace: my-namespace-xy
spec:
  description: Allow NS internal traffic, block everything else
  endpointSelector: {}
  ingress:
  - fromEndpoints:
    - {}
  egress:
  - toEndpoints:
    - {}
```

Have a look at the following template that could be used for new user workload namespaces.

- `cnp-user-template.yaml`:
  - Add the namespace label `exposed: "true"` in case Nginx ingress should be able to serve Ingresses from this namespace.
  - Add the namespace label `metrics: "true"` in case Prometheus should be able to scrape metrics endpoints from this namespace.
  - Allow all ingress and egress traffic **within** the namespace
  - Optional: Additional application specific CNPs to explicitly allow connections to and from namespace-external sources/destinations.

Check out `demo-app-podinfo.sh` to simulate the deployment of new user workload.

## Troubleshooting
To troubleshoot connectivity issues or false positive denies, use Hubble UI and especially Hubble CLI. Hubble can either be directly used within a Cilium agent pod (only sees node local traffic) or in an even more powerful way, via the dedicated [Hubble CLI](https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#install-the-hubble-client). This Hubble CLI then needs to point to the Hubble-Relay service which aggregates the flows from all Cilium agents / nodes.

```bash
# Temporarily expose the `hubble-relay` ClusterIP service via `kubectl port-forward` (blocking call, separate shell):
kubectl port-forward -n kube-system svc/hubble-relay 4245:443

# Check for dropped traffic:
hubble observe -t policy-verdict -f --verdict DROPPED
```

Improve your Hubble CLI outputs even further by using additional filtering constraints (issue `hubble observe --help` to see all available options):
- `--ip` / `--to-ip` / `--from-ip`
- `-n` / `--namespace` / `--to-namespace` / `--from-namespace`
- `--port` / `--to-pod` / `--from-pod`
- `--node-name`

## Sources:
- https://docs.cilium.io/en/stable/security/host-firewall/
- https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#install-the-hubble-client
- https://docs.cilium.io/en/stable/gettingstarted/hubble_cli/#hubble-cli