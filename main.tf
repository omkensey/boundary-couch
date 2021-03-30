terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "3.32.0"
    }
    ignition = {
      source = "community-terraform-providers/ignition"
      version = "2.1.2"
    }
    boundary = {
      source = "hashicorp/boundary"
      version = "1.0.1"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_availability_zones" "available" {}

data "http" "admin_ip_dyn" {
  url = "http://whatismyip.akamai.com/"
}

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "2.66.0"

  name                 = "vpc-${var.unique_name}"
  cidr                 = var.aws_vpc_cidr
  azs                  = data.aws_availability_zones.available.names
  private_subnets      = cidrsubnets(var.aws_vpc_cidr,1)
  public_subnets       = cidrsubnets(cidrsubnet(var.aws_vpc_cidr,1,1),2,2)
  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  tags = merge(
    {
      "kubernetes.io/cluster/${var.unique_name}" = "shared"
    },
    var.aws_tags
  )

  public_subnet_tags = {
    "kubernetes.io/cluster/${var.unique_name}" = "shared"
    "kubernetes.io/role/elb"                   = "1"
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${var.unique_name}" = "shared"
    "kubernetes.io/role/internal-elb"          = "1"
  }
}

locals {
  boundary_private_subnets = module.vpc.private_subnets
  boundary_public_subnets = module.vpc.public_subnets
  boundary_instance_profile_name = aws_iam_instance_profile.boundary.name
  boundary_security_group_id = aws_security_group.boundary.id
}

resource "random_password" "vault_root_token" {
  keepers = {
    unique_name = var.unique_name
  }
  length = 16
  upper = true
  lower = true
  number = true
  special = true
}

resource "random_password" "vault_boundary_controller_token" {
  keepers = {
    unique_name = var.unique_name
  }
  length = 16
  upper = true
  lower = true
  number = true
  special = true
}

resource "random_password" "vault_boundary_worker_token" {
  keepers = {
    unique_name = var.unique_name
  }
  length = 16
  upper = true
  lower = true
  number = true
  special = true
}

resource "random_password" "postgres_admin_password" {
  keepers = {
    unique_name = var.unique_name
  }
  length = 16
  upper = true
  lower = true
  number = true
  special = true
}

resource "random_password" "postgres_boundary_controller_password" {
  keepers = {
    unique_name = var.unique_name
  }
  length = 16
  upper = true
  lower = true
  number = true
  special = true
}

module "boundary_infra" {
  source = "./boundary_infra"
  kms_type = "vault"
  db_type = "local_pg"
  aws_instance_ami = var.aws_instance_ami
  aws_nodetype = coalesce(var.aws_nodetype.boundary_infra, var.aws_nodetype.default)
  aws_nodetype_small = coalesce(var.aws_nodetype.boundary_bootstrap, var.aws_nodetype.default)
  aws_ssh_keypair = var.aws_ssh_keypair
  aws_tags = var.aws_tags
  unique_name = var.unique_name
  boundary_private_subnets = module.vpc.private_subnets
  boundary_public_subnets = module.vpc.public_subnets
  boundary_instance_profile_name = aws_iam_instance_profile.boundary.name
  boundary_security_group_id = aws_security_group.boundary.id
  boundary_version = var.boundary_version
  boundary_init_version = var.boundary_init_version
  postgres_admin_password = random_password.postgres_admin_password.result
  postgres_boundary_controller_password = random_password.postgres_boundary_controller_password.result
  vault_root_token = random_password.vault_root_token.result
}

module "boundary_base" {
  source = "./boundary_base"
  boundary_controller_scale = var.boundary_controller_scale
  aws_instance_ami = var.aws_instance_ami
  aws_nodetype = coalesce(var.aws_nodetype.boundary_base, var.aws_nodetype.default)
  aws_ssh_keypair = var.aws_ssh_keypair
  aws_tags = var.aws_tags
  unique_name = var.unique_name
  boundary_private_subnets = module.vpc.private_subnets
  boundary_public_subnets = module.vpc.public_subnets
  boundary_instance_profile_name = aws_iam_instance_profile.boundary.name
  boundary_security_group_id = aws_security_group.boundary.id
  boundary_version = var.boundary_version
  boundary_infra_ip = module.boundary_infra.infra_private_ipaddr
  postgres_admin_password = random_password.postgres_admin_password.result
  postgres_boundary_controller_password = random_password.postgres_boundary_controller_password.result
  vault_root_token = random_password.vault_root_token.result
}

module "targets_http" {
  source = "./targets_http"
  target_http_scale = var.target_http_scale
  aws_instance_ami = var.aws_instance_ami
  aws_nodetype = coalesce(var.aws_nodetype.target_http, var.aws_nodetype.default)
  aws_ssh_keypair = var.aws_ssh_keypair
  aws_tags = var.aws_tags
  unique_name = var.unique_name
  boundary_private_subnets = module.vpc.private_subnets
  boundary_public_subnets = module.vpc.public_subnets
  boundary_instance_profile_name = aws_iam_instance_profile.boundary.name
  boundary_security_group_id = aws_security_group.boundary.id
}

module "targets_docker" {
  source = "./targets_docker"
  aws_instance_ami = var.aws_instance_ami
  aws_nodetype = coalesce(var.aws_nodetype.target_docker_local, var.aws_nodetype.default)
  aws_ssh_keypair = var.aws_ssh_keypair
  aws_tags = var.aws_tags
  unique_name = var.unique_name
  vault_root_token = random_password.vault_root_token.result
  boundary_private_subnets = module.vpc.private_subnets
  boundary_public_subnets = module.vpc.public_subnets
  boundary_instance_profile_name = aws_iam_instance_profile.boundary.name
  boundary_security_group_id = aws_security_group.boundary.id
  boundary_version = var.boundary_version
  boundary_infra_ip = module.boundary_infra.infra_private_ipaddr
  boundary_controller_private_ips = module.boundary_base.controller_private_ipaddrs
}

# module "targets_eks" {
#   source = "./targets_eks"
# }

# module "boundary_resources" {
#   source = "./boundary_resources"
# }
