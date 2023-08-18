# Demo Network Policies

## Generic Hubble Configuration for Visibility
```bash
# - Since we enabled TLS for Hubble, we need to configure Hubble CLI accordingly
# - Get Hubble CLI from here: https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#install-the-hubble-client
hubble config set tls true
hubble config set tls tls-ca-cert-files /path/to/cilium-netpol-demo/deploy/cilium-ca-crt.pem
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

# If you don't see any relevant audit/dropped event, activate Cilium host policiy enforcement:
./host-enforcement-to-enforce.sh
```

## Infrastructure Components
```bash
# Kube-system
kubectl apply -f cnp-infra-kube-system.yaml

# Nginx Ingress Controller
kubectl apply -f cnp-infra-ingress-nginx.yaml

# Label namespaces with Ingress resources that should be reachable from Nginx ingress controller with `exposed=true`:
kubectl label namespace goldpinger exposed=true
kubectl label namespace monitoring exposed=true
kubectl label namespace kube-system exposed=true # Required for Hubble-UI. Move Hubble-UI to a dedicated namespaces for production: https://docs.cilium.io/en/stable/gettingstarted/hubble/#enable-the-hubble-ui ("Helm (Standalone install)" tab)

# Cert-Manager
kubectl apply -f cnp-infra-cert-manager.yaml

# Kube Prometheus Stack
kubectl apply -f cnp-infra-monitoring-stack.yaml

# Goldpinger:
kubectl apply -f cnp-infra-goldpinger.yaml
```

## DNS Visibility
As we want to use Cilium's DNS visibility/filterung capabilities, we need to apply a policy that uses `toPorts[*].rules.dns`. Since we want this visibility for all namespaces, we use a CCNP for that.

**Important:** As this policy **only** allows traffic toward coredns, every other egress traffic from all namespaces will be dropped in case you haven't applied the already mentioned `cnp-infra-*.yaml` CNPs!

```bash
kubectl apply -f ccnp-cluster-dns-visibility.yaml
```

## User Workload
Have a look at the following templates that could be used as a default rule set for new user workload namespaces.

- `cnp-user-template.yaml`:
  - Allow all ingress and egress traffic **within** the namespace
  - Deny all ingress and egress traffic entering or leaving the namespace
    - Application / Namespace owners should explicitly allow those connections via custom Cilium Network Policies
  - Allow Nginx ingress controller to reach services inside the application namespace
    - Required to successfully serve Ingresses
  - Allow Prometheus to scrape metrics from services inside the application namespace

## Troubleshooting
To troubleshoot connectivity issues or false positive denies, use Hubble UI and especially Hubble CLI. Hubble can either be directly used within a Cilium agent pod (only sees node local traffic) or in an even more powerful way, via the dedicated [Hubble CLI](https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#install-the-hubble-client). This Hubble CLI then needs to point to the Hubble-Relay service which aggregates the flows from all Cilium agents / nodes.

```bash
# Temporarily expose the `hubble-relay` ClusterIP service via `kubectl port-forward` (blocking call, separate shell):
kubectl port-forward -n kube-system svc/hubble-relay 4245:443

# Check for dropped traffic:
hubble observe -t policy-verdict -f --verdict DROPPED
```

Improve your Hubble CLI outputs even further by using additional filtering constraints (issue `hubble observe --help` to see the full list):
- `--ip` / `--to-ip` / `--from-ip`
- `-n` / `--namespace` / `--to-namespace` / `--from-namespace`
- `--port` / `--to-pod` / `--from-pod`
- `--node-name`

## Sources:
- https://docs.cilium.io/en/stable/security/host-firewall/
- https://docs.cilium.io/en/stable/gettingstarted/hubble_setup/#install-the-hubble-client
- https://docs.cilium.io/en/stable/gettingstarted/hubble_cli/#hubble-cli