variable "boundary_controller_scale" {
  type = number
  default = 1
}

variable "boundary_infra_ip" {
  type = string
}

variable "vault_root_token" {
  type = string
}

variable "postgres_admin_password" {
  type = string
}

variable "postgres_boundary_controller_password" {
  type = string
}

variable "unique_name" {
  type = string
}

variable "aws_instance_ami" {
  type = string
}

variable "aws_ssh_keypair" {
  type = string
}

variable "aws_nodetype" {
  type = string
  default = "t3.large"
}

variable "aws_tags" {
  type = map(string)
}

variable "boundary_private_subnets" {
  type = list(string)
}

variable "boundary_public_subnets" {
  type = list(string)
}

variable "boundary_instance_profile_name" {
  type = string
}

variable "boundary_security_group_id" {
  type = string
}

variable "boundary_version" {
  type = string
}