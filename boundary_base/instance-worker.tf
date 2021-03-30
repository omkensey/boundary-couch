resource "aws_instance" "boundary-worker" {
  ami = var.aws_instance_ami
  tags = var.aws_tags
  instance_type = var.aws_nodetype
  associate_public_ip_address = "true"
  key_name = var.aws_ssh_keypair
  iam_instance_profile = var.boundary_instance_profile_name
  subnet_id = var.boundary_public_subnets[0]
  vpc_security_group_ids = [ var.boundary_security_group_id ]
}

resource "local_file" "boundary-base-worker-config" {
  content = templatefile("${path.module}/boundary-worker.hcl.tpl", {
    boundary_controller_ips = "[ \"${join("\", \"", aws_instance.boundary-controller.*.private_ip)}\" ]"
    boundary_worker_ip = aws_instance.boundary-worker.public_ip
    boundary_vault_ip = var.boundary_infra_ip
    boundary_vault_root_token = var.vault_root_token
    boundary_worker_name = "${var.unique_name}-worker-base"
  })
  filename = "${path.root}/files/boundary_base/boundary-worker/boundary-worker.hcl"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-worker-env" {
  content = templatefile("${path.module}/boundary.env.tpl", {
    boundary_version = var.boundary_version
  })
  filename = "${path.root}/files/boundary_base/boundary-worker/boundary.env"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-worker-service" {
  content = file("${path.module}/boundary-worker.service")
  filename = "${path.root}/files/boundary_base/boundary-worker/boundary-worker.service"
  file_permission = "0644"
  directory_permission = "0755"
}

output "worker_public_ipaddr" {
  value = aws_instance.boundary-worker.public_ip
  description = "The public IP of the Boundary worker."
}
