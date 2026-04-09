locals {
  service_name = "${var.project_name}-${var.environment}-app-svc"
}

resource "aws_ecs_service" "this" {
  name                   = local.service_name
  cluster                = var.cluster_arn
  task_definition        = var.task_definition_arn
  desired_count          = var.desired_count
  launch_type            = "FARGATE"
  platform_version       = var.platform_version
  enable_execute_command = var.enable_execute_command

  deployment_minimum_healthy_percent = var.deployment_minimum_healthy_percent
  deployment_maximum_percent         = var.deployment_maximum_percent
  health_check_grace_period_seconds  = var.health_check_grace_period_seconds

  enable_ecs_managed_tags = true
  propagate_tags          = "SERVICE"

  deployment_controller {
    type = "ECS"
  }

  deployment_circuit_breaker {
    enable   = true
    rollback = true
  }

  network_configuration {
    subnets          = var.private_subnet_ids
    security_groups  = [var.ecs_tasks_security_group_id]
    assign_public_ip = var.assign_public_ip
  }

  load_balancer {
    target_group_arn = var.target_group_arn
    container_name   = var.container_name
    container_port   = var.container_port
  }

  lifecycle {
    ignore_changes = [
      desired_count,
      task_definition,
    ]
  }

  tags = merge(var.common_tags, {
    Name = local.service_name
  })
}