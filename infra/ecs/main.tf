data "aws_region" "task_region" {}

resource "aws_ecs_task_definition" "task" {
  family                   = var.module_name
  task_role_arn            = aws_iam_role.ecs_task_role.arn
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  network_mode             = "awsvpc"
  cpu                      = 256
  memory                   = 2048
  requires_compatibilities = ["FARGATE"]
  container_definitions = (jsonencode([
    {
      "name" : "${var.module_name}",
      "image" : "${aws_ecr_repository.this.repository_url}",
      "essential" : true,
      "logConfiguration" : {
        "logDriver" : "awslogs",
        "options" : {
          "awslogs-region" : "${data.aws_region.task_region.name}",
          "awslogs-stream-prefix" : "${var.module_name}",
          "awslogs-group" : "${var.module_name}",
          "awslogs-create-group" : "true",
        }
      },
      "cpu" : 1,
      "memory" : 2048,
    }
    ]
  ))
}

resource "aws_ecs_cluster" "cluster" {
  name = var.module_name
}

resource "aws_ecs_service" "service" {
  name            = var.module_name
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  desired_count   = 0
  launch_type     = "FARGATE"

  network_configuration {
    security_groups  = [module.security_group.security_group_id]
    subnets          = module.vpc.public_subnets
    assign_public_ip = true
  }
}
