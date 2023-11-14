# Demo Infrastructure Deployment

For this demo infrastructure, some Isovalent internal Terraform modules were used to spin up a Kubeadm-based K8s cluster and installing Cilium. Nevertheless, you can still basically do the same in a manual way by following the [kubeadm Cluster Setup](https://gist.github.com/PhilipSchmid/e34a725d5836d21432fd10b0709a5c4a) guide. Ensure you're aware of the following things:

- kube-proxy shouldn't be installed, as we use Cilium's KubeProxyReplacement.
- Don't install iptables on the nodes. Hence, you need to tell the `kubeadm init|join` commands to not fail due to that: `--ignore-preflight-errors=FileContent--proc-sys-net-bridge-bridge-nf-call-iptables`
- This demo infra uses dedicated `infra` nodes (labeled and tainted) for hosting all infrastructure components. It's up to you if you want to do the same. If you don't, ensure to remove the `affinity` and `toleration` sections from all provided Helm value files.

Also, check the following files to see how things are deployed:
- Cilium Helm values: `deploy/03-cilium-values-1.14.yaml`
- Infrastructure components: `deploy/scripts/deploy-uc.sh` 

## Troubleshooting

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

## Terraform Module Doc
<!-- BEGIN_TF_DOCS -->
### Requirements

| Name | Version |
|------|---------|
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | >= 5.0 |

### Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | >= 5.0 |
| <a name="provider_null"></a> [null](#provider\_null) | n/a |
| <a name="provider_random"></a> [random](#provider\_random) | n/a |

### Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_cilium"></a> [cilium](#module\_cilium) | git::ssh://git@github.com/isovalent/terraform-k8s-cilium.git | v1.6.2 |
| <a name="module_kubeadm"></a> [kubeadm](#module\_kubeadm) | git::ssh://git@github.com/isovalent/terraform-aws-kubeadm.git | v2.6.1 |
| <a name="module_vpc"></a> [vpc](#module\_vpc) | git::ssh://git@github.com/isovalent/terraform-aws-vpc.git | v1.7 |

### Resources

| Name | Type |
|------|------|
| [aws_route53_record.generic_infra_lb_public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/route53_record) | resource |
| [null_resource.deploy_az_uc](https://registry.terraform.io/providers/hashicorp/null/latest/docs/resources/resource) | resource |
| [random_id.cluster](https://registry.terraform.io/providers/hashicorp/random/latest/docs/resources/id) | resource |
| [aws_route53_zone.public](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/route53_zone) | data source |

### Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_additional_private_subnet_tags"></a> [additional\_private\_subnet\_tags](#input\_additional\_private\_subnet\_tags) | Additional tags for the private subnets | `map(string)` | `{}` | no |
| <a name="input_additional_public_subnet_tags"></a> [additional\_public\_subnet\_tags](#input\_additional\_public\_subnet\_tags) | Additional tags for the public subnets | `map(string)` | `{}` | no |
| <a name="input_ami_name_filter"></a> [ami\_name\_filter](#input\_ami\_name\_filter) | The filter to use when grabbing the Flatcar Pro image to use. | `string` | `"Rocky-9-EC2-LVM-9.2-*x86_64"` | no |
| <a name="input_ami_owner_id"></a> [ami\_owner\_id](#input\_ami\_owner\_id) | The owner ID of the AMI. | `string` | `"792107900819"` | no |
| <a name="input_ami_ssh_user"></a> [ami\_ssh\_user](#input\_ami\_ssh\_user) | The user for the SSH session. | `string` | `"rocky"` | no |
| <a name="input_base_domain"></a> [base\_domain](#input\_base\_domain) | The base domain for the generic infra LB. | `string` | `"cilium.rocks"` | no |
| <a name="input_cilium_helm_chart"></a> [cilium\_helm\_chart](#input\_cilium\_helm\_chart) | The name of the Helm chart used by the customer. | `string` | `"cilium/cilium"` | no |
| <a name="input_cilium_helm_values_file_path"></a> [cilium\_helm\_values\_file\_path](#input\_cilium\_helm\_values\_file\_path) | Cilium values file | `string` | `"03-cilium-values-1.14.yaml"` | no |
| <a name="input_cilium_helm_values_override_file_path"></a> [cilium\_helm\_values\_override\_file\_path](#input\_cilium\_helm\_values\_override\_file\_path) | Override Cilium values file | `string` | `""` | no |
| <a name="input_cilium_helm_version"></a> [cilium\_helm\_version](#input\_cilium\_helm\_version) | The version of the Helm charts used by the customer. | `string` | `"1.14.1"` | no |
| <a name="input_cluster_id"></a> [cluster\_id](#input\_cluster\_id) | The (Cilium) ID of the cluster. Must be unique for Cilium ClusterMesh and between 0-255. | `number` | `"1"` | no |
| <a name="input_cluster_name"></a> [cluster\_name](#input\_cluster\_name) | The name of the cluster. | `string` | `"philip-netpol-demo"` | no |
| <a name="input_enable_infras_generic_lb"></a> [enable\_infras\_generic\_lb](#input\_enable\_infras\_generic\_lb) | Enable generic LB pointing to the infra nodes. | `bool` | `true` | no |
| <a name="input_grafana_admin_password"></a> [grafana\_admin\_password](#input\_grafana\_admin\_password) | Admin password for Grafana. | `string` | n/a | yes |
| <a name="input_infras_count"></a> [infras\_count](#input\_infras\_count) | The number of infra nodes. | `number` | `"2"` | no |
| <a name="input_infras_generic_lb_ports"></a> [infras\_generic\_lb\_ports](#input\_infras\_generic\_lb\_ports) | Ports to open on the generic infra LB and forward to the infra nodes. | `list(string)` | <pre>[<br>  "80",<br>  "443"<br>]</pre> | no |
| <a name="input_infras_generic_lb_public_reachable"></a> [infras\_generic\_lb\_public\_reachable](#input\_infras\_generic\_lb\_public\_reachable) | Make generic LB pointing to the infra nodes public accessible or not. This flag should only be used in combination with an enabled 'enable\_infras\_generic\_lb'. | `bool` | `true` | no |
| <a name="input_kubernetes_version"></a> [kubernetes\_version](#input\_kubernetes\_version) | The version of Kubernetes used by the customer. | `string` | `"v1.27.4"` | no |
| <a name="input_owner"></a> [owner](#input\_owner) | Owner for resource tagging | `string` | n/a | yes |
| <a name="input_pod_cidr"></a> [pod\_cidr](#input\_pod\_cidr) | The CIDR to use for K8s Pods- | `string` | `"100.64.0.0/14"` | no |
| <a name="input_pre_cilium_install_script"></a> [pre\_cilium\_install\_script](#input\_pre\_cilium\_install\_script) | A script to be run before installing Cilium. | `string` | `""` | no |
| <a name="input_region"></a> [region](#input\_region) | The region in which to create the cluster. | `string` | n/a | yes |
| <a name="input_service_cidr"></a> [service\_cidr](#input\_service\_cidr) | The CIDR to use for K8s Services | `string` | `"100.68.0.0/16"` | no |
| <a name="input_ssh_private_key_path"></a> [ssh\_private\_key\_path](#input\_ssh\_private\_key\_path) | The SSH private key path to get the kubeconfig from the bastsion host. | `string` | `""` | no |
| <a name="input_ssh_public_key_path"></a> [ssh\_public\_key\_path](#input\_ssh\_public\_key\_path) | The SSH public key path for the cluster. | `string` | `""` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | The set of tags to place on the created resources. These will be merged with the default tags defined via local.tags in 00-locals.tf. | `map(string)` | <pre>{<br>  "customer": "internal",<br>  "usage": "demo"<br>}</pre> | no |
| <a name="input_vpc_cidr"></a> [vpc\_cidr](#input\_vpc\_cidr) | The CIDR to use for the VPC. Currently it must be a /16 or /24. | `string` | `"10.1.0.0/16"` | no |
| <a name="input_workers_count"></a> [workers\_count](#input\_workers\_count) | The number of worker nodes. | `number` | `"2"` | no |

### Outputs

| Name | Description |
|------|-------------|
| <a name="output_alertmanager_url"></a> [alertmanager\_url](#output\_alertmanager\_url) | Alertmanager URL |
| <a name="output_cluster_name"></a> [cluster\_name](#output\_cluster\_name) | Cluster name |
| <a name="output_goldpinger_url"></a> [goldpinger\_url](#output\_goldpinger\_url) | Goldpinger URL |
| <a name="output_grafana_admin_password"></a> [grafana\_admin\_password](#output\_grafana\_admin\_password) | Grafana admin password |
| <a name="output_grafana_url"></a> [grafana\_url](#output\_grafana\_url) | Grafana URL |
| <a name="output_hubble_ui_url"></a> [hubble\_ui\_url](#output\_hubble\_ui\_url) | Hubble UI URL |
| <a name="output_path_to_kubeconfig_file"></a> [path\_to\_kubeconfig\_file](#output\_path\_to\_kubeconfig\_file) | Path to the kubeconfig of the Kubeadm cluster |
| <a name="output_prometheus_url"></a> [prometheus\_url](#output\_prometheus\_url) | Prometheus URL |
| <a name="output_region"></a> [region](#output\_region) | AWS region used for the infra |
<!-- END_TF_DOCS -->