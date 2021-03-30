resource "aws_instance" "boundary_infra" {
  ami = var.aws_instance_ami
  tags = var.aws_tags
  instance_type = var.aws_nodetype
  associate_public_ip_address = "true"
  key_name = var.aws_ssh_keypair
  iam_instance_profile = var.boundary_instance_profile_name
  subnet_id = var.boundary_public_subnets[0]
  vpc_security_group_ids = [ var.boundary_security_group_id ]
}

resource "aws_instance" "boundary_bootstrap" {
  ami = var.aws_instance_ami
  tags = var.aws_tags
  instance_type = var.aws_nodetype_small
  associate_public_ip_address = "true"
  key_name = var.aws_ssh_keypair
  iam_instance_profile = var.boundary_instance_profile_name
  subnet_id = var.boundary_public_subnets[0]
  vpc_security_group_ids = [ var.boundary_security_group_id ]
}

resource "local_file" "postgres-env" {
  content = templatefile("${path.module}/postgres.env.tpl", {
    boundary_postgres_admin_password = var.postgres_admin_password
    boundary_postgres_controller_password = var.postgres_boundary_controller_password
    boundary_database_ip = aws_instance.boundary_infra.private_ip
  })
  filename = "${path.root}/files/boundary_infra/postgres.env"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "vault-env" {
  content = templatefile("${path.module}/vault.env.tpl", {
    vault_root_token = var.vault_root_token
    boundary_vault_ip = aws_instance.boundary_infra.private_ip
  })
  filename = "${path.root}/files/boundary_infra/vault.env"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-database-init-config" {
  content = templatefile("${path.module}/boundary-controller.hcl.tpl", {
    boundary_controller_ip = "127.0.0.1"
    boundary_database_ip = aws_instance.boundary_infra.private_ip
    boundary_postgres_admin_password = var.postgres_admin_password
    boundary_vault_ip = aws_instance.boundary_infra.private_ip
    boundary_vault_root_token = var.vault_root_token
    boundary_controller_name = "boundary-database-init"
  })
  filename = "${path.root}/files/boundary_bootstrap/boundary-database-init.hcl"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-database-env" {
  content = templatefile("${path.module}/boundary.env.tpl", {
    boundary_version = var.boundary_version
    boundary_init_version = var.boundary_init_version
  })
  filename = "${path.root}/files/boundary_bootstrap/boundary.env"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "postgres-service" {
  content = file("${path.module}/postgres.service")
  filename = "${path.root}/files/boundary_infra/postgres.service"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "vault-service" {
  content = file("${path.module}/vault.service")
  filename = "${path.root}/files/boundary_infra/vault.service"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "vault-init-env" {
  content = templatefile("${path.module}/vault.env.tpl", {
    vault_root_token = var.vault_root_token
    boundary_vault_ip = aws_instance.boundary_infra.private_ip
  })
  filename = "${path.root}/files/boundary_bootstrap/vault.env"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "vault-init-service" {
  content = file("${path.module}/vault-init.service")
  filename = "${path.root}/files/boundary_bootstrap/vault-init.service"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-database-init-service" {
  content = file("${path.module}/boundary-database-init.service")
  filename = "${path.root}/files/boundary_bootstrap/boundary-database-init.service"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-database-migrate-service" {
  content = file("${path.module}/boundary-database-migrate.service")
  filename = "${path.root}/files/boundary_bootstrap/boundary-database-migrate.service"
  file_permission = "0644"
  directory_permission = "0755"
}

output "infra_public_ipaddr" {
  value = aws_instance.boundary_infra.public_ip
  description = "The public IP of the Boundary utility server."
}

output "infra_private_ipaddr" {
  value = aws_instance.boundary_infra.private_ip
  description = "The private IP of the Boundary utility server."
}

output "bootstrap_public_ipaddr" {
  value = aws_instance.boundary_bootstrap.public_ip
  description = "The public IP of the Boundary bootstrap server."
}