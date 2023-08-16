# vpc module & general
variable "cluster_name" {
  default     = "philip-netpol-demo"
  description = "The name of the cluster."
  type        = string
}

variable "cluster_id" {
  default     = "1"
  description = "The (Cilium) ID of the cluster. Must be unique for Cilium ClusterMesh and between 0-255."
  type        = number
}

variable "region" {
  description = "The region in which to create the cluster."
  type        = string
}

variable "owner" {
  description = "Owner for resource tagging"
  type        = string
}

variable "vpc_cidr" {
  default     = "10.1.0.0/16"
  description = "The CIDR to use for the VPC. Currently it must be a /16 or /24."
  type        = string
}

variable "tags" {
  default = {
    usage    = "demo",
    customer = "internal"
  }
  description = "The set of tags to place on the created resources. These will be merged with the default tags defined via local.tags in 00-locals.tf."
  type        = map(string)
}

variable "additional_private_subnet_tags" {
  description = "Additional tags for the private subnets"
  type        = map(string)
  default     = {}
}

variable "additional_public_subnet_tags" {
  description = "Additional tags for the public subnets"
  type        = map(string)
  default     = {}
}

# kubeadm module
variable "ami_name_filter" {
  default     = "Rocky-9-EC2-LVM-9.2-*x86_64"
  description = "The filter to use when grabbing the Flatcar Pro image to use."
  type        = string
}

variable "ami_owner_id" {
  default     = "792107900819"
  description = "The owner ID of the AMI."
  type        = string
}

variable "ami_ssh_user" {
  default     = "rocky"
  description = "The user for the SSH session."
  type        = string
}

variable "service_cidr" {
  default     = "100.68.0.0/16"
  description = "The CIDR to use for K8s Services"
  type        = string
}

variable "kubernetes_version" {
  default     = "v1.27.4"
  type        = string
  description = "The version of Kubernetes used by the customer."
}

variable "ssh_public_key_path" {
  default     = ""
  type        = string
  description = "The SSH public key path for the cluster."
}

variable "ssh_private_key_path" {
  default     = ""
  type        = string
  description = "The SSH private key path to get the kubeconfig from the bastsion host."
}

variable "workers_count" {
  default     = "2"
  description = "The number of worker nodes."
  type        = number
}

variable "infras_count" {
  default     = "2"
  description = "The number of infra nodes."
  type        = number
}

variable "enable_infras_generic_lb" {
  default     = true
  description = "Enable generic LB pointing to the infra nodes."
  type        = bool
}

variable "infras_generic_lb_ports" {
  default     = ["80", "443"]
  description = "Ports to open on the generic infra LB and forward to the infra nodes."
  type        = list(string)
}

variable "infras_generic_lb_public_reachable" {
  default     = true
  description = "Make generic LB pointing to the infra nodes public accessible or not. This flag should only be used in combination with an enabled 'enable_infras_generic_lb'."
  type        = bool
}

# Cilium module
variable "pod_cidr" {
  default     = "100.64.0.0/14"
  description = "The CIDR to use for K8s Pods-"
  type        = string
}

variable "cilium_helm_chart" {
  default     = "cilium/cilium"
  type        = string
  description = "The name of the Helm chart used by the customer."
}

variable "cilium_helm_version" {
  default     = "1.14.1"
  type        = string
  description = "The version of the Helm charts used by the customer."
}

variable "cilium_helm_values_file_path" {
  default     = "03-cilium-values-1.14.yaml"
  description = "Cilium values file"
  type        = string
}

variable "cilium_helm_values_override_file_path" {
  default     = ""
  description = "Override Cilium values file"
  type        = string
}

variable "pre_cilium_install_script" {
  default     = ""
  description = "A script to be run before installing Cilium."
  type        = string
}

# Infra components
variable "base_domain" {
  default     = "cilium.rocks"
  description = "The base domain for the generic infra LB."
  type        = string
}

variable "grafana_admin_password" {
  description = "Admin password for Grafana."
  type        = string
}