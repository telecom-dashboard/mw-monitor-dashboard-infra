locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_cloudwatch_metric_alarm" "cpu_high" {
  alarm_name          = "${local.name_prefix}-ec2-cpu-high"
  alarm_description   = "CPU utilization is high on the MVP EC2 host"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "CPUUtilization"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Average"
  threshold           = var.cpu_utilization_threshold
  treat_missing_data  = "missing"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-ec2-cpu-high"
  })
}

resource "aws_cloudwatch_metric_alarm" "status_check_failed" {
  alarm_name          = "${local.name_prefix}-ec2-status-check-failed"
  alarm_description   = "The MVP EC2 host failed an EC2 status check"
  comparison_operator = "GreaterThanThreshold"
  evaluation_periods  = 2
  metric_name         = "StatusCheckFailed"
  namespace           = "AWS/EC2"
  period              = 300
  statistic           = "Maximum"
  threshold           = 0
  treat_missing_data  = "missing"
  alarm_actions       = var.alarm_actions
  ok_actions          = var.ok_actions

  dimensions = {
    InstanceId = var.instance_id
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-ec2-status-check-failed"
  })
}
