data "aws_caller_identity" "current" {}

data "aws_partition" "current" {}

data "aws_iam_openid_connect_provider" "github" {
  url = "https://token.actions.githubusercontent.com"
}

locals {
  account_id = data.aws_caller_identity.current.account_id
  partition  = data.aws_partition.current.partition

  tf_state_bucket_arn = "arn:${local.partition}:s3:::${var.tf_state_bucket_name}"

  dev_state_object_arns = [
    "${local.tf_state_bucket_arn}/envs/dev/terraform.tfstate",
    "${local.tf_state_bucket_arn}/envs/dev/terraform.tfstate.tflock",
  ]

  prod_state_object_arns = [
    "${local.tf_state_bucket_arn}/envs/prod/terraform.tfstate",
    "${local.tf_state_bucket_arn}/envs/prod/terraform.tfstate.tflock",
  ]

  dev_logs_arn  = "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/ecs/${var.github_repo}-dev*"
  prod_logs_arn = "arn:${local.partition}:logs:${var.aws_region}:${local.account_id}:log-group:/aws/ecs/${var.github_repo}-prod*"

  ecr_repo_arn      = "arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/${var.github_repo}*"
  dev_ecr_repo_arn  = "arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/${var.github_repo}-dev-app"
  prod_ecr_repo_arn = "arn:${local.partition}:ecr:${var.aws_region}:${local.account_id}:repository/${var.github_repo}-prod-app"

  dev_role_pattern_arn  = "arn:${local.partition}:iam::${local.account_id}:role/${var.github_repo}-dev-*"
  prod_role_pattern_arn = "arn:${local.partition}:iam::${local.account_id}:role/${var.github_repo}-prod-*"

  dev_cluster_name  = "${var.github_repo}-dev-cluster"
  prod_cluster_name = "${var.github_repo}-prod-cluster"

  dev_service_name  = "${var.github_repo}-dev-app-svc"
  prod_service_name = "${var.github_repo}-prod-app-svc"

  dev_service_arn  = "arn:${local.partition}:ecs:${var.aws_region}:${local.account_id}:service/${local.dev_cluster_name}/${local.dev_service_name}"
  prod_service_arn = "arn:${local.partition}:ecs:${var.aws_region}:${local.account_id}:service/${local.prod_cluster_name}/${local.prod_service_name}"

  dev_ecs_exec_role_pattern_arn  = "arn:${local.partition}:iam::${local.account_id}:role/*-dev-ecs-exec-role"
  prod_ecs_exec_role_pattern_arn = "arn:${local.partition}:iam::${local.account_id}:role/*-prod-ecs-exec-role"
}

data "aws_iam_policy_document" "github_oidc_assume_role" {
  statement {
    sid    = "GitHubActionsAssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRoleWithWebIdentity"
    ]

    principals {
      type        = "Federated"
      identifiers = [data.aws_iam_openid_connect_provider.github.arn]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }

    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:sub"
      values = [
        "repo:${var.github_org}/${var.github_repo}:ref:refs/heads/${var.github_branch}"
      ]
    }
  }
}

resource "aws_iam_role" "terraform_dev" {
  name               = var.dev_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

resource "aws_iam_role" "terraform_prod" {
  name               = var.prod_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

data "aws_iam_policy_document" "terraform_dev_permissions" {
  statement {
    sid    = "AllowStsCallerIdentity"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowStateBucketList"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [local.tf_state_bucket_arn]
  }

  statement {
    sid    = "AllowDevStateObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = local.dev_state_object_arns
  }

  statement {
    sid    = "AllowTerraformAwsReadAccess"
    effect = "Allow"

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeManagedPrefixLists",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "elasticloadbalancing:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:ListTagsForResource",
      "ecr:GetAuthorizationToken",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:ListTagsForResource",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "application-autoscaling:Describe*",
      "cloudwatch:DescribeAlarms",
      "ec2:DescribeAddressesAttribute"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformEc2NetworkingWrite"
    effect = "Allow"

    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceRoute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformAlbAccess"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformEcsAccess"
    effect = "Allow"

    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:CreateService",
      "ecs:DeleteService",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:TagResource",
      "ecs:UntagResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource"
    ]

    resources = [local.dev_logs_arn]
  }

  statement {
    sid    = "AllowTerraformEcrAccess"
    effect = "Allow"

    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:PutLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:TagResource",
      "ecr:UntagResource"
    ]

    resources = [local.ecr_repo_arn]
  }

  statement {
    sid    = "AllowTerraformAppAutoScalingAccess"
    effect = "Allow"

    actions = [
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:TagResource",
      "application-autoscaling:UntagResource",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformPassOnlyProjectRoles"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [local.dev_role_pattern_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "AllowTerraformManageOnlyProjectRoles"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]

    resources = [local.dev_role_pattern_arn]
  }

  statement {
    sid    = "AllowTerraformCreateServiceLinkedRoles"
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "ecs.amazonaws.com",
        "ecs.application-autoscaling.amazonaws.com",
        "elasticloadbalancing.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "AllowTerraformAcmRoute53Read"
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:ListTagsForCertificate",
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformAcmRoute53Write"
    effect = "Allow"

    actions = [
      "acm:AddTagsToCertificate",
      "acm:DeleteCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate",
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["*"]
  }

}



data "aws_iam_policy_document" "terraform_prod_permissions" {
  statement {
    sid    = "AllowStsCallerIdentity"
    effect = "Allow"

    actions = [
      "sts:GetCallerIdentity"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowStateBucketList"
    effect = "Allow"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation"
    ]

    resources = [local.tf_state_bucket_arn]
  }

  statement {
    sid    = "AllowProdStateObjectAccess"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:PutObject",
      "s3:DeleteObject"
    ]

    resources = local.prod_state_object_arns
  }

  statement {
    sid    = "AllowTerraformAwsReadAccess"
    effect = "Allow"

    actions = [
      "ec2:DescribeAccountAttributes",
      "ec2:DescribeAddresses",
      "ec2:DescribeAvailabilityZones",
      "ec2:DescribeInternetGateways",
      "ec2:DescribeManagedPrefixLists",
      "ec2:DescribeNatGateways",
      "ec2:DescribeNetworkInterfaces",
      "ec2:DescribeRouteTables",
      "ec2:DescribeSecurityGroups",
      "ec2:DescribeSubnets",
      "ec2:DescribeTags",
      "ec2:DescribeVpcs",
      "ec2:DescribeVpcAttribute",
      "elasticloadbalancing:Describe*",
      "ecs:Describe*",
      "ecs:List*",
      "ecr:DescribeRepositories",
      "ecr:DescribeImages",
      "ecr:ListTagsForResource",
      "ecr:GetAuthorizationToken",
      "logs:DescribeLogGroups",
      "logs:DescribeLogStreams",
      "logs:ListTagsForResource",
      "iam:GetRole",
      "iam:GetPolicy",
      "iam:GetPolicyVersion",
      "iam:ListAttachedRolePolicies",
      "iam:ListRolePolicies",
      "iam:ListInstanceProfilesForRole",
      "application-autoscaling:Describe*",
      "cloudwatch:DescribeAlarms",
      "ec2:DescribeAddressesAttribute"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformEc2NetworkingWrite"
    effect = "Allow"

    actions = [
      "ec2:AllocateAddress",
      "ec2:AssociateRouteTable",
      "ec2:AttachInternetGateway",
      "ec2:CreateInternetGateway",
      "ec2:CreateNatGateway",
      "ec2:CreateRoute",
      "ec2:CreateRouteTable",
      "ec2:CreateSecurityGroup",
      "ec2:CreateSubnet",
      "ec2:CreateTags",
      "ec2:CreateVpc",
      "ec2:DeleteInternetGateway",
      "ec2:DeleteNatGateway",
      "ec2:DeleteRoute",
      "ec2:DeleteRouteTable",
      "ec2:DeleteSecurityGroup",
      "ec2:DeleteSubnet",
      "ec2:DeleteTags",
      "ec2:DeleteVpc",
      "ec2:DetachInternetGateway",
      "ec2:DisassociateRouteTable",
      "ec2:ModifySubnetAttribute",
      "ec2:ModifyVpcAttribute",
      "ec2:ReleaseAddress",
      "ec2:ReplaceRoute",
      "ec2:RevokeSecurityGroupEgress",
      "ec2:RevokeSecurityGroupIngress",
      "ec2:AuthorizeSecurityGroupEgress",
      "ec2:AuthorizeSecurityGroupIngress"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformAlbAccess"
    effect = "Allow"

    actions = [
      "elasticloadbalancing:AddTags",
      "elasticloadbalancing:CreateListener",
      "elasticloadbalancing:CreateLoadBalancer",
      "elasticloadbalancing:CreateRule",
      "elasticloadbalancing:CreateTargetGroup",
      "elasticloadbalancing:DeleteListener",
      "elasticloadbalancing:DeleteLoadBalancer",
      "elasticloadbalancing:DeleteRule",
      "elasticloadbalancing:DeleteTargetGroup",
      "elasticloadbalancing:ModifyListener",
      "elasticloadbalancing:ModifyLoadBalancerAttributes",
      "elasticloadbalancing:ModifyRule",
      "elasticloadbalancing:ModifyTargetGroup",
      "elasticloadbalancing:ModifyTargetGroupAttributes",
      "elasticloadbalancing:RegisterTargets",
      "elasticloadbalancing:DeregisterTargets",
      "elasticloadbalancing:RemoveTags",
      "elasticloadbalancing:SetIpAddressType",
      "elasticloadbalancing:SetSecurityGroups",
      "elasticloadbalancing:SetSubnets"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformEcsAccess"
    effect = "Allow"

    actions = [
      "ecs:CreateCluster",
      "ecs:DeleteCluster",
      "ecs:CreateService",
      "ecs:DeleteService",
      "ecs:UpdateService",
      "ecs:RegisterTaskDefinition",
      "ecs:DeregisterTaskDefinition",
      "ecs:TagResource",
      "ecs:UntagResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformLogsAccess"
    effect = "Allow"

    actions = [
      "logs:CreateLogGroup",
      "logs:DeleteLogGroup",
      "logs:PutRetentionPolicy",
      "logs:DeleteRetentionPolicy",
      "logs:TagResource",
      "logs:UntagResource"
    ]

    resources = [local.prod_logs_arn]
  }

  statement {
    sid    = "AllowTerraformEcrAccess"
    effect = "Allow"

    actions = [
      "ecr:CreateRepository",
      "ecr:DeleteRepository",
      "ecr:PutLifecyclePolicy",
      "ecr:DeleteLifecyclePolicy",
      "ecr:PutImageScanningConfiguration",
      "ecr:PutImageTagMutability",
      "ecr:TagResource",
      "ecr:UntagResource"
    ]

    resources = [local.ecr_repo_arn]
  }

  statement {
    sid    = "AllowTerraformAppAutoScalingAccess"
    effect = "Allow"

    actions = [
      "application-autoscaling:RegisterScalableTarget",
      "application-autoscaling:DeregisterScalableTarget",
      "application-autoscaling:PutScalingPolicy",
      "application-autoscaling:DeleteScalingPolicy",
      "application-autoscaling:TagResource",
      "application-autoscaling:UntagResource",
      "cloudwatch:PutMetricAlarm",
      "cloudwatch:DeleteAlarms"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformPassOnlyProjectRoles"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [local.prod_role_pattern_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values = [
        "ecs.amazonaws.com",
        "ecs-tasks.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "AllowTerraformManageOnlyProjectRoles"
    effect = "Allow"

    actions = [
      "iam:CreateRole",
      "iam:DeleteRole",
      "iam:AttachRolePolicy",
      "iam:DetachRolePolicy",
      "iam:PutRolePolicy",
      "iam:DeleteRolePolicy",
      "iam:TagRole",
      "iam:UntagRole",
      "iam:UpdateAssumeRolePolicy"
    ]

    resources = [local.prod_role_pattern_arn]
  }

  statement {
    sid    = "AllowTerraformCreateServiceLinkedRoles"
    effect = "Allow"

    actions = [
      "iam:CreateServiceLinkedRole"
    ]

    resources = ["*"]

    condition {
      test     = "StringEquals"
      variable = "iam:AWSServiceName"
      values = [
        "ecs.amazonaws.com",
        "ecs.application-autoscaling.amazonaws.com",
        "elasticloadbalancing.amazonaws.com"
      ]
    }
  }

  statement {
    sid    = "AllowTerraformAcmRoute53Read"
    effect = "Allow"

    actions = [
      "acm:DescribeCertificate",
      "acm:GetCertificate",
      "acm:ListTagsForCertificate",
      "route53:GetChange",
      "route53:GetHostedZone",
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowTerraformAcmRoute53Write"
    effect = "Allow"

    actions = [
      "acm:AddTagsToCertificate",
      "acm:DeleteCertificate",
      "acm:RemoveTagsFromCertificate",
      "acm:RequestCertificate",
      "route53:ChangeResourceRecordSets"
    ]

    resources = ["*"]
  }

}

resource "aws_iam_role_policy" "terraform_dev_permissions" {
  name   = "${var.dev_role_name}-backend-and-platform"
  role   = aws_iam_role.terraform_dev.id
  policy = data.aws_iam_policy_document.terraform_dev_permissions.json
}

resource "aws_iam_role_policy" "terraform_prod_permissions" {
  name   = "${var.prod_role_name}-backend-and-platform"
  role   = aws_iam_role.terraform_prod.id
  policy = data.aws_iam_policy_document.terraform_prod_permissions.json
}

resource "aws_iam_role" "app_dev" {
  name               = var.app_dev_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

data "aws_iam_policy_document" "app_dev_permissions" {
  statement {
    sid    = "AllowStsCallerIdentity"
    effect = "Allow"

    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEcrAuthorizationToken"
    effect = "Allow"

    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPushToDevAppRepository"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage"
    ]

    resources = [local.dev_ecr_repo_arn]
  }

  statement {
    sid    = "AllowDescribeAndRegisterDevTaskDefinition"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPassDevExecutionRole"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [local.dev_ecs_exec_role_pattern_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowDeployDevService"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]

    resources = [local.dev_service_arn]
  }
}

resource "aws_iam_role_policy" "app_dev_permissions" {
  name   = "${var.app_dev_role_name}-ecr-push-and-ecs-deploy"
  role   = aws_iam_role.app_dev.id
  policy = data.aws_iam_policy_document.app_dev_permissions.json
}

resource "aws_iam_role" "app_prod" {
  name               = var.app_prod_role_name
  assume_role_policy = data.aws_iam_policy_document.github_oidc_assume_role.json
}

data "aws_iam_policy_document" "app_prod_permissions" {
  statement {
    sid    = "AllowStsCallerIdentity"
    effect = "Allow"

    actions   = ["sts:GetCallerIdentity"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowEcrAuthorizationToken"
    effect = "Allow"

    actions   = ["ecr:GetAuthorizationToken"]
    resources = ["*"]
  }

  statement {
    sid    = "AllowPushToProdAppRepository"
    effect = "Allow"

    actions = [
      "ecr:BatchCheckLayerAvailability",
      "ecr:CompleteLayerUpload",
      "ecr:InitiateLayerUpload",
      "ecr:PutImage",
      "ecr:UploadLayerPart",
      "ecr:BatchGetImage"
    ]

    resources = [local.prod_ecr_repo_arn]
  }

  statement {
    sid    = "AllowDescribeAndRegisterProdTaskDefinition"
    effect = "Allow"

    actions = [
      "ecs:DescribeTaskDefinition",
      "ecs:RegisterTaskDefinition"
    ]

    resources = ["*"]
  }

  statement {
    sid    = "AllowPassProdExecutionRole"
    effect = "Allow"

    actions = [
      "iam:PassRole"
    ]

    resources = [local.prod_ecs_exec_role_pattern_arn]

    condition {
      test     = "StringEquals"
      variable = "iam:PassedToService"
      values   = ["ecs-tasks.amazonaws.com"]
    }
  }

  statement {
    sid    = "AllowDeployProdService"
    effect = "Allow"

    actions = [
      "ecs:DescribeServices",
      "ecs:UpdateService"
    ]

    resources = [local.prod_service_arn]
  }
}

resource "aws_iam_role_policy" "app_prod_permissions" {
  name   = "${var.app_prod_role_name}-ecr-push-and-ecs-deploy"
  role   = aws_iam_role.app_prod.id
  policy = data.aws_iam_policy_document.app_prod_permissions.json
}