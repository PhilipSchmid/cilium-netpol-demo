data "aws_route53_zone" "public" {
  count = var.enable_infras_generic_lb ? var.infras_generic_lb_public_reachable ? 1 : 0 : 0

  name = var.base_domain
}

resource "aws_route53_record" "generic_infra_lb_public" {
  count = var.enable_infras_generic_lb ? var.infras_generic_lb_public_reachable ? 1 : 0 : 0

  name    = "*.${local.base_domain}"
  type    = "A"
  zone_id = data.aws_route53_zone.public[0].id

  alias {
    evaluate_target_health = true
    name                   = module.kubeadm.generic_infra_load_balancer_host
    zone_id                = module.kubeadm.generic_infra_load_balancer_zone_id
  }
}