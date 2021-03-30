resource "aws_instance" "docker_instance" {
  ami = var.aws_instance_ami
  tags = var.aws_tags
  instance_type = var.aws_nodetype
  associate_public_ip_address = "true"
  key_name = var.aws_ssh_keypair
  iam_instance_profile = var.boundary_instance_profile_name
  subnet_id = var.boundary_public_subnets[0]
  vpc_security_group_ids = [ var.boundary_security_group_id ]
}

resource "local_file" "boundary-worker-docker-config" {
  content = templatefile("${path.module}/boundary-worker-docker.hcl.tpl", {
    boundary_controller_ips = "[ \"${join("\", \"", var.boundary_controller_private_ips)}\" ]"
    boundary_worker_ip = aws_instance.docker_instance.public_ip
    boundary_vault_ip = var.boundary_infra_ip
    vault_root_token = var.vault_root_token
    boundary_worker_name = "${var.unique_name}-worker-docker"
  })
  filename = "${path.root}/files/boundary_worker_docker/boundary-worker.hcl"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-env" {
  content = templatefile("${path.module}/boundary.env.tpl", {
    boundary_version = var.boundary_version
  })
  filename = "${path.root}/files/boundary_worker_docker/boundary.env"
  file_permission = "0644"
  directory_permission = "0755"
}

resource "local_file" "boundary-worker-docker-service" {
  content = file("${path.module}/boundary-worker.service")
  filename = "${path.root}/files/boundary_worker_docker/boundary-worker.service"
  file_permission = "0644"
  directory_permission = "0755"
}

output "instance_docker_public_ipaddr" {
  value = aws_instance.docker_instance.public_ip
  description = "The public IP of the Boundary Docker target instance."
}

output "instance_docker_private_ipaddr" {
  value = aws_instance.docker_instance.private_ip
  description = "The public IP of the Boundary Docker target instance."
}
