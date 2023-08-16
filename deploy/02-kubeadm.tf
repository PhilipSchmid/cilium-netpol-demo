module "kubeadm" {
  source = "git::ssh://git@github.com/isovalent/terraform-aws-kubeadm.git?ref=v2.4"

  vpc_id                             = module.vpc.id
  ami_name_filter                    = var.ami_name_filter
  ami_owner_id                       = var.ami_owner_id
  ami_ssh_user                       = var.ami_ssh_user
  kubernetes_version                 = var.kubernetes_version
  name                               = var.cluster_name
  tags                               = local.tags
  pod_cidr                           = var.pod_cidr
  service_cidr                       = var.service_cidr
  ssh_public_key_path                = var.ssh_public_key_path
  ssh_private_key_path               = var.ssh_private_key_path
  workers_count                      = var.workers_count
  infras_count                       = var.infras_count
  enable_infras_generic_lb           = var.enable_infras_generic_lb
  infras_generic_lb_ports            = var.infras_generic_lb_ports
  infras_generic_lb_public_reachable = var.infras_generic_lb_public_reachable
  enable_aws_csi_driver_support      = true
  skip_phases                        = "addon/kube-proxy"
  ignore_preflight_errors            = "FileExisting-iptables"
}
