output "cluster_name" {
  description = "Cluster name"
  value       = var.cluster_name
}

output "path_to_kubeconfig_file" {
  description = "Path to the kubeconfig of the Kubeadm cluster"
  value       = module.kubeadm.path_to_kubeconfig_file
}

output "region" {
  description = "AWS region used for the infra"
  value       = var.region
}

output "prometheus_url" {
  description = "Prometheus URL"
  value       = local.prometheus_url
}

output "alertmanager_url" {
  description = "Alertmanager URL"
  value       = local.alertmanager_url
}

output "hubble_ui_url" {
  description = "Hubble UI URL"
  value       = local.hubble_ui_url
}

output "grafana_url" {
  description = "Grafana URL"
  value       = local.grafana_url
}

output "grafana_admin_password" {
  description = "Grafana admin password"
  value       = var.grafana_admin_password
}

output "goldpinger_url" {
  description = "Goldpinger URL"
  value       = local.goldpinger_url
}