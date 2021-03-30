resource "aws_instance" "http_instances" {
  ami = var.aws_instance_ami
  tags = var.aws_tags
  instance_type = var.aws_nodetype
  key_name = var.aws_ssh_keypair
  iam_instance_profile = var.boundary_instance_profile_name
  subnet_id = var.boundary_private_subnets[0]
  vpc_security_group_ids = [ var.boundary_security_group_id ]
  count = var.target_http_scale
}

output "instance_http_private_ipaddrs" {
  value = aws_instance.http_instances.*.private_ip
  description = "The private IPs of the AWS target instances."
}
