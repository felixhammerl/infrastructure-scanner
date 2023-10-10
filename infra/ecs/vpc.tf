locals {
  vpc_cidr = "10.2.0.0/16"
}

data "aws_region" "vpc_region" {}

module "vpc" {
  source = "terraform-aws-modules/vpc/aws"

  name = var.module_name
  cidr = local.vpc_cidr

  azs = [
    "${data.aws_region.vpc_region.name}a",
    "${data.aws_region.vpc_region.name}b",
    "${data.aws_region.vpc_region.name}c",
  ]
  public_subnets = [
    cidrsubnet(local.vpc_cidr, 8, 1), //10.2.1.0/24
    cidrsubnet(local.vpc_cidr, 8, 2), //10.2.2.0/24
    cidrsubnet(local.vpc_cidr, 8, 3), //10.2.3.0/24
  ]

  enable_dns_support      = true
  map_public_ip_on_launch = true
}


module "security_group" {
  source = "terraform-aws-modules/security-group/aws"

  name   = var.module_name
  vpc_id = module.vpc.vpc_id

  egress_rules = ["all-all"]
}
