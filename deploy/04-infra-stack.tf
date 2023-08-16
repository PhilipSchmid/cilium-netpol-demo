resource "null_resource" "deploy_az_uc" {

  depends_on = [
    module.cilium
  ]

  # This should run everytime when `terraform apply` is triggered to also apply updated Helm values
  triggers = {
    build_number = "${timestamp()}"
  }

  provisioner "local-exec" {
    command     = <<EOF
${abspath(path.module)}/scripts/deploy-uc.sh
EOF
    environment = local.extra_provisioner_environment_variables
  }

}