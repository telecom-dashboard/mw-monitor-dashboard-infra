locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_cloudwatch_log_group" "ecs_app" {
  name              = "/aws/ecs/${local.name_prefix}-app"
  retention_in_days = var.retention_in_days

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-log-group"
  })
}