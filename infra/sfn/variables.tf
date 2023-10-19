variable "module_name" {
  type = string
}

variable "results_bucket" {
  type = string
}

variable "step_list" {
  type = string
}

variable "step_gather" {
  type = string
}

variable "step_transform" {
  type = string
}

variable "step_scan" {
  type = object({
    cluster_arn         = string
    task_arn            = string
    task_container_name = string
    security_groups     = list(string)
    subnets             = list(string)
    assign_public_ip    = bool
  })
}

variable "ecs_task_roles" {
  type = list(string)
}
