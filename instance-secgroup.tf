locals {
  admin_ip_result = compact(flatten([var.admin_ips, "${data.http.admin_ip_dyn.body}/32"]))
}

resource "aws_security_group" "boundary" {
  name = var.unique_name
  vpc_id = module.vpc.vpc_id
  ingress {
    description = "Unrestricted local access to Boundary"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = flatten([var.aws_vpc_cidr, local.admin_ip_result])
  }
  egress {
    description = "Unrestricted egress"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [ "0.0.0.0/0" ]
  }
}
