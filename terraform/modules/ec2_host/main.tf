locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

data "aws_ssm_parameter" "ubuntu_ami" {
  count = var.ami_id == "" ? 1 : 0
  name  = "/aws/service/canonical/ubuntu/server/24.04/stable/current/amd64/hvm/ebs-gp3/ami-id"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "s3_access" {
  statement {
    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]
    resources = ["${var.assets_bucket_arn}/*"]
  }

  statement {
    actions = [
      "s3:ListBucket"
    ]
    resources = [var.assets_bucket_arn]
  }
}

resource "aws_iam_role" "instance" {
  name = "${local.name_prefix}-app-host-role"

  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-host-role"
  })
}

resource "aws_iam_role_policy_attachment" "ssm" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

resource "aws_iam_role_policy_attachment" "cloudwatch_agent" {
  role       = aws_iam_role.instance.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy" "s3_assets" {
  name   = "${local.name_prefix}-assets-access"
  role   = aws_iam_role.instance.id
  policy = data.aws_iam_policy_document.s3_access.json
}

resource "aws_iam_instance_profile" "this" {
  name = "${local.name_prefix}-app-host-profile"
  role = aws_iam_role.instance.name
}

resource "aws_instance" "this" {
  ami                         = var.ami_id != "" ? var.ami_id : data.aws_ssm_parameter.ubuntu_ami[0].value
  instance_type               = var.instance_type
  subnet_id                   = var.subnet_id
  vpc_security_group_ids      = [var.security_group_id]
  associate_public_ip_address = false
  iam_instance_profile        = aws_iam_instance_profile.this.name
  key_name                    = var.key_name != "" ? var.key_name : null
  monitoring                  = var.enable_detailed_monitoring
  user_data                   = var.user_data

  root_block_device {
    volume_size           = var.root_volume_size
    volume_type           = "gp3"
    delete_on_termination = true
    encrypted             = true
  }

  metadata_options {
    http_endpoint = "enabled"
    http_tokens   = "required"
  }

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-host"
  })
}

resource "aws_eip" "this" {
  domain   = "vpc"
  instance = aws_instance.this.id

  tags = merge(var.common_tags, {
    Name = "${local.name_prefix}-app-host-eip"
  })
}
