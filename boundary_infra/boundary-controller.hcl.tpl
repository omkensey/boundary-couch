listener "tcp" {
  purpose = "api"
  address = "0.0.0.0"
  tls_disable = "true"
}

listener "tcp" {
  purpose = "cluster"
  address = "0.0.0.0"
  tls_disable = "true"
}

controller {
  name = "${boundary_controller_name}"
  description = "Boundary controller"
  public_cluster_addr = "${boundary_controller_ip}"
  database {
    url = "postgres://boundaryinit:${urlencode(boundary_postgres_admin_password)}@${boundary_database_ip}:5432/boundary-db?sslmode=disable"
  }
}

kms "transit" {
  purpose = "root"
  address = "http://${boundary_vault_ip}:8200"
  token = "${boundary_vault_root_token}"
  disable_renewal = "true"
  key_name = "root"
  mount_path = "boundary"
}

kms "transit" {
  purpose = "recovery"
  address = "http://${boundary_vault_ip}:8200"
  token = "${boundary_vault_root_token}"
  disable_renewal = "true"
  key_name = "recovery"
  mount_path = "boundary"
}

kms "transit" {
  purpose = "worker-auth"
  address = "http://${boundary_vault_ip}:8200"
  token = "${boundary_vault_root_token}"
  disable_renewal = "true"
  key_name = "worker-auth"
  mount_path = "boundary"
}

