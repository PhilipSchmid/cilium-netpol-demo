# Demo Infrastructure Deployment
I'm using Isovalent internal Terraform modules to spin up a Kubeadm-based K8s cluster and installing Cilium. Nevertheless, you can basically do the same in a manual way by following my [kubeadm Cluster Setup](https://gist.github.com/PhilipSchmid/e34a725d5836d21432fd10b0709a5c4a) guide. Ensure you're aware of the following things:

- Ensure kube-proxy is not installed, as we use Cilium's KubeProxyReplacement `strict` mode.
- Don't install iptables on the nodes. Hence, you need to tell the `kubeadm init|join` commands to not fail due to that: `--ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables`
- I've used dedicated `infra` nodes (labeled and tainted) for hosting all infrastructure components. It's up to you if you wand to do the same. If you do, ensure to remove the `affinity` and `toleration` sections from all provided Helm value files.

Also, check the following files to see how I deploy things:
- Cilium Helm values: `deploy/03-cilium-values-1.14.yaml`
- Infrastructure components: `deploy/scripts/deploy-uc.sh` 