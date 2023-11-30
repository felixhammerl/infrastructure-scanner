locals {
  service = "infrastructure-scanner"
  region  = "us-east-1"
}

terraform {
  backend "s3" {
  }

  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
  }
}

provider "aws" {
  region = local.region
}

module "sfn" {
  source      = "./sfn"
  module_name = local.service
  step_list   = module.step_list.arn
  step_scan = {
    cluster_arn         = module.step_scan.cluster_arn
    task_arn            = module.step_scan.task_arn
    task_container_name = module.step_scan.container_name
    security_groups     = module.step_scan.security_groups
    subnets             = module.step_scan.subnets
    assign_public_ip    = module.step_scan.assign_public_ip
  }
  step_gather     = module.step_gather.arn
  step_transform  = module.step_transform.arn
  step_invalidate = module.step_invalidate.arn
  ecs_task_roles = [
    module.step_scan.task_role_arn,
    module.step_scan.exec_role_arn
  ]
  results_bucket = aws_s3_bucket.scan_results.id
}
