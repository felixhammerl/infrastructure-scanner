resource "aws_sfn_state_machine" "sfn" {
  name     = var.module_name
  role_arn = aws_iam_role.sfn.arn
  definition = jsonencode({
    "StartAt" : "List",
    "States" : {
      "List" : {
        "Type" : "Task",
        "Resource" : var.step_list,
        "Next" : "Scan All"
      },
      "Scan All" : {
        "Type" : "Map",
        "Next" : "Gather",
        "InputPath" : "$",
        "ItemsPath" : "$",
        "ItemSelector" : {
          "account.$" : "$$.Map.Item.Value",
        },
        "ItemProcessor" : {
          "StartAt" : "Scan",
          "States" : {
            "Scan" : {
              "Type" : "Task",
              "Resource" : "arn:aws:states:::ecs:runTask.sync",
              "Parameters" : {
                "LaunchType" : "FARGATE",
                "Cluster" : var.step_scan.cluster_arn,
                "TaskDefinition" : var.step_scan.task_arn,
                "NetworkConfiguration" : {
                  "AwsvpcConfiguration" : {
                    "AssignPublicIp" : var.step_scan.assign_public_ip ? "ENABLED" : "DISABLED",
                    "SecurityGroups" : var.step_scan.security_groups,
                    "Subnets" : var.step_scan.subnets
                  }
                },
                "Overrides" : {
                  "ContainerOverrides" : [
                    {
                      "Name" : var.step_scan.task_container_name,
                      "Environment" : [
                        {
                          "Name" : "ACCOUNT",
                          "Value.$" : "$.account"
                        },
                        {
                          "Name" : "S3_BUCKET",
                          "Value" : var.results_bucket
                        }
                      ]
                    }
                  ]
                }
              },
              "End" : true
            },
          }
        }
      },
      "Gather" : {
        "Type" : "Task",
        "Resource" : var.step_gather,
        "Next" : "Transform"
      },
      "Transform" : {
        "Type" : "Wait",
        "Seconds" : 1,
        "End" : true
      }
    }
  })
}
