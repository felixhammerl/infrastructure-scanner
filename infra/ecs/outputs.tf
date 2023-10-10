output "repo" {
  value = aws_ecr_repository.this.repository_url
}

output "cluster_arn" {
  value = aws_ecs_cluster.cluster.arn
}

output "task_arn" {
  value = aws_ecs_task_definition.task.arn
}

output "container_name" {
  # This is aws_ecs_task_definition.task.container_definitions.0.name
  value = var.module_name
}

output "security_groups" {
  value = aws_ecs_service.service.network_configuration[0].security_groups
}

output "subnets" {
  value = aws_ecs_service.service.network_configuration[0].subnets
}

output "assign_public_ip" {
  value = aws_ecs_service.service.network_configuration[0].assign_public_ip
}


output "task_role_arn" {
  value = aws_iam_role.ecs_execution_role.arn
}

output "exec_role_arn" {
  value = aws_iam_role.ecs_task_role.arn
}
