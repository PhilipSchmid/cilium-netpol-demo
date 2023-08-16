locals {
  expiry = file("${path.module}/.timestamp")
  # The default tags defined here are merged with extra tags defined via var.tags in 00-variables.tf.
  tags = merge(
    tomap({
      "expiry" : local.expiry,
      "owner" : var.owner
    }),
    var.tags
  )
  base_domain        = "${var.cluster_name}.${var.base_domain}"
  hubble_ui_url      = "hubble.${local.base_domain}"
  prometheus_url     = "prometheus.${local.base_domain}"
  alertmanager_url   = "alertmanager.${local.base_domain}"
  grafana_url        = "grafana.${local.base_domain}"
  goldpinger_url     = "goldpinger.${local.base_domain}"
  clusterissuer_name = "letsencrypt-prod"
  extra_provisioner_environment_variables = {
    CLUSTER_NAME                 = var.cluster_name
    CLUSTER_ID                   = var.cluster_id
    POD_CIDR                     = var.pod_cidr
    KUBECONFIG                   = module.kubeadm.path_to_kubeconfig_file
    OWNER                        = var.owner
    EXPIRY                       = local.expiry
    REGION                       = var.region
    VPC_ID                       = module.vpc.id
    KUBE_APISERVER_HOST          = module.kubeadm.kube_apiserver_internal_load_balancer_host
    KUBE_APISERVER_PORT          = module.kubeadm.kube_apiserver_internal_load_balancer_port
    CLUSTERISSUER_NAME           = local.clusterissuer_name
    HUBBLE_UI_URL                = local.hubble_ui_url
    PROMETHEUS_URL               = local.prometheus_url
    ALERTMANAGER_URL             = local.alertmanager_url
    GRAFANA_URL                  = local.grafana_url
    GRAFANA_ADMIN_PASSWORD       = var.grafana_admin_password
    GOLDPINGER_URL               = local.goldpinger_url
  }
}