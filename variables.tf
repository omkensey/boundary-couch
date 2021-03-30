variable "unique_name" {
  type = string
  default = "boundary_demo"
}

variable "boundary_version" {
  type = string
  default = "0.1.8"
}

variable "boundary_init_version" {
  type = string
  default = "0.1.5"
}

variable "boundary_controller_scale" {
  type = number
  default = 1
}

variable "target_http_scale" {
  type = number
  default = 3
}

variable "admin_ips" {
  type = list(string)
  default = []
}

variable "aws_ssh_keypair" {
  type = string
}

variable "aws_tags" {
  type = map(string)
  default = {}
}

variable "aws_region" {
  type = string
  default = "us-east-2"
}

variable "aws_instance_ami" {
  type = string
  default = "ami-08b49e7d67e26d443"
}

variable "aws_nodetype" {
  # default, boundary_bootstrap, boundary_base, boundary_infra, target_http, target_docker_local, target_eks_pool
  type = map(string)
  default = { default = "t3.large", boundary_bootstrap = "t3.micro", boundary_base = "t3.large", boundary_infra = "t3.large", target_http = "t3.large", target_docker_local = "t3.large", target_eks_pool = "t3.large" }
}

variable "aws_vpc_cidr" {
  type = string
  default = "10.203.0.0/16"
}

variable "aws_eks_pool_scale" {
  type = number
  default = 2
}

variable "aws_eks_pool_nodetype" {
  type = string
  default = "t3.large"
}

variable "aws_eks_pod_cidr" {
  type = string
  default = "10.204.0.0/16"
}

variable "aws_eks_service_cidr" {
  type = string
  default = "10.205.0.0/20"
}