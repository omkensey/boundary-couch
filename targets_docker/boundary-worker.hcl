listener "tcp" {
  purpose = "proxy"
  address = "0.0.0.0"
  tls_disable = "true"
}

worker {
  name = "boundary-demo-worker"
  description = "Demo worker instance"
  address = "0.0.0.0"
  public_addr = "13.58.251.144"
  controllers = [
    "3.136.233.30"
  ]
  tags {
    type = "docker"
  }
}

kms "transit" {
  purpose = "worker-auth"
  address = "http://10.203.133.22:8200"
  token = "prodhang-vault"
  disable_renewal = "true"
  key_name = "worker-auth"
  mount_path = "boundary"
}
