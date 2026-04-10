locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

resource "aws_security_group" "app_host" {
  name        = "${local.name_prefix}-app-host-sg"
  description = "Public security group for the EC2 MVP app host"
  vpc_id      = var.vpc_id

  ingress {
    description = "HTTP from allowed CIDRs"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = var.web_ingress_cidr_blocks
  }

  ingress {
    description = "HTTPS from allowed CIDRs"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = var.web_ingress_cidr_blocks
  }

  dynamic "ingress" {
    for_each = length(var.ssh_ingress_cidr_blocks) == 0 ? [] : [1]

    content {
      description = "SSH from allowed CIDRs"
      from_port   = 22
      to_port     = 22
      protocol    = "tcp"
      cidr_blocks = var.ssh_ingress_cidr_blocks
    }
  }

  egress {
    description = "Allow all outbound"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-host-sg"
  })
}
