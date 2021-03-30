output "boundary_infra_public_ipaddr" {
  value = module.boundary_infra.infra_public_ipaddr
  description = "The public IP of the Boundary utility server."
}

output "boundary_bootstrap_public_ipaddr" {
  value = module.boundary_infra.bootstrap_public_ipaddr
  description = "The public IP of the Boundary bootstrap server."
}

output "boundary_controller_public_ipaddrs" {
  value = module.boundary_base.controller_public_ipaddrs
  description = "The public IPs of the Boundary controllers."
}

output "boundary_worker_base_public_ipaddr" {
  value = module.boundary_base.worker_public_ipaddr
  description = "The public IP of the base Boundary worker."
}

output "boundary_worker_docker_public_ipaddr" {
  value = module.targets_docker.instance_docker_public_ipaddr
  description = "The public IP of the Boundary Docker worker/target instance."
}

output "boundary_target_http_private_ipaddrs" {
  value = module.targets_http.instance_http_private_ipaddrs
  description = "The private IPs of the AWS target instances."
}