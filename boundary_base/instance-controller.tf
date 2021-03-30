resource "aws_instance" "boundary-controller" {
  ami = var.aws_instance_ami
  tags = var.aws_tags
  instance_type = var.aws_nodetype
  associate_public_ip_address = "true"
  key_name = var.aws_ssh_keypair
  iam_instance_profile = var.boundary_instance_profile_name
  subnet_id = var.boundary_public_subnets[0]
  vpc_security_group_ids = [ var.boundary_security_group_id ]
  count = var.boundary_controller_scale
}

resource "local_file" "boundary-controller-config" {
  content = templatefile("${path.module}/boundary-controller.hcl.tpl", {
    boundary_controller_ip = aws_instance.boundary-controller[count.index].private_ip
    boundary_database_ip = var.boundary_infra_ip
    boundary_postgres_admin_password = var.postgres_admin_password
    boundary_vault_ip = var.boundary_infra_ip
    boundary_vault_root_token = var.vault_root_token
    boundary_controller_name = "${var.unique_name}-controller-${count.index}"
  })
  filename = "${path.root}/files/boundary_base/boundary-controller-${count.index}/boundary-controller.hcl"
  file_permission = "0644"
  directory_permission = "0755"
  count = var.boundary_controller_scale
}

resource "local_file" "boundary-controller-env" {
  content = templatefile("${path.module}/boundary.env.tpl", {
    boundary_version = var.boundary_version
  })
  filename = "${path.root}/files/boundary_base/boundary-controller-${count.index}/boundary.env"
  file_permission = "0644"
  directory_permission = "0755"
  count = var.boundary_controller_scale
}

resource "local_file" "boundary-controller-service" {
  content = file("${path.module}/boundary-controller.service")
  filename = "${path.root}/files/boundary_base/boundary-controller-${count.index}/boundary-controller.service"
  file_permission = "0644"
  directory_permission = "0755"
  count = var.boundary_controller_scale
}

output "controller_public_ipaddrs" {
  value = aws_instance.boundary-controller.*.public_ip
  description = "The public IPs of the Boundary controller(s)."
}

output "controller_private_ipaddrs" {
  value = aws_instance.boundary-controller.*.private_ip
  description = "The private IPs of the Boundary controller(s)."
}