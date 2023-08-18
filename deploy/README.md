# Demo Infrastructure Deployment
For this demo infrastructure, some Isovalent internal Terraform modules were used to spin up a Kubeadm-based K8s cluster and installing Cilium. Nevertheless, you can basically do the same in a manual way by following the [kubeadm Cluster Setup](https://gist.github.com/PhilipSchmid/e34a725d5836d21432fd10b0709a5c4a) guide. Ensure you're aware of the following things:

- kube-proxy doesn't need to be installed, as we use Cilium's KubeProxyReplacement.
- Don't install iptables on the nodes. Hence, you need to tell the `kubeadm init|join` commands to not fail due to that: `--ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables`
- This demo infra uses dedicated `infra` nodes (labeled and tainted) for hosting all infrastructure components. It's up to you if you want to do the same. If you don't, ensure to remove the `affinity` and `toleration` sections from all provided Helm value files.

Also, check the following files to see how things are deployed:
- Cilium Helm values: `deploy/03-cilium-values-1.14.yaml`
- Infrastructure components: `deploy/scripts/deploy-uc.sh` 

SSH access via SSH jumphost:
```bash
ssh -i ~/.ssh/id_ed25519.pub \
    -o StrictHostKeyChecking=no \
    -o UserKnownHostsFile=/dev/null \
    -o ProxyCommand="ssh -W %h:%p \
      -i ~/.ssh/id_ed25519.pub \
      -o StrictHostKeyChecking=no \
      -o UserKnownHostsFile=/dev/null \
      rocky@<ssh-jumphost-public-ip>" \
    rocky@<node-private-ip>
```