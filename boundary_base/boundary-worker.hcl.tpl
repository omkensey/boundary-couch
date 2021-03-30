listener "tcp" {
  purpose = "proxy"
  address = "0.0.0.0"
  tls_disable = "true"
}

worker {
  name = "${boundary_worker_name}"
  description = "Demo worker instance"
  address = "0.0.0.0"
  public_addr = "${boundary_worker_ip}"
  controllers = ${boundary_controller_ips}
}

kms "transit" {
  purpose = "worker-auth"
  address = "http://${boundary_vault_ip}:8200"
  token = "${boundary_vault_root_token}"
  disable_renewal = "true"
  key_name = "worker-auth"
  mount_path = "boundary"
}
