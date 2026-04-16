# bootstrap terraform-ci-roles

This Terraform root creates the GitHub Actions roles needed by this repo.

## What it does

This root is responsible for:
- looking up the existing GitHub OIDC provider
- optionally creating the legacy Terraform CI IAM role for **dev**
- optionally creating the legacy Terraform CI IAM role for **prod**
- optionally creating the legacy app deploy IAM role for **dev**
- optionally creating the legacy app deploy IAM role for **prod**
- creating the business repo Terraform CI IAM role for **dev**
- creating the business repo Terraform CI IAM role for **prod**
- creating the business repo app deploy IAM role for **dev**
- creating the business repo app deploy IAM role for **prod**
- creating the MVP app deploy IAM role for `telecom-dashboard/mw-dashboard-app`
- granting backend S3 bucket access for Terraform CI
- granting the AWS permissions needed for the current Terraform-managed infrastructure
- granting the ECR / ECS permissions needed for the app deploy workflow
- granting the S3 / SSM permissions needed for the MVP EC2 deploy workflow

## What permissions it is expected to cover

At the current repo state, the roles created here cover two categories.

### Terraform CI permissions

Terraform CI needs permissions related to:
- VPC and subnet resources
- security groups
- load balancer resources
- ECS cluster
- ECR
- ECS task execution role management
- ECS task definition and ECS service operations
- CloudWatch Logs
- selected IAM role management for project-scoped roles
- application autoscaling-related resources where applicable

Those legacy dev/prod Terraform roles are now disabled by default in this repo.

The business dev/prod Terraform roles are the active Terraform CI roles for this repo.

### App deploy permissions

The app deploy roles need permissions related to:
- `ecr:GetAuthorizationToken`
- ECR layer upload and image push
- ECS task definition lookup and registration
- `iam:PassRole` for the ECS task execution role
- ECS service update and describe operations

That split lets Terraform own infrastructure while GitHub Actions owns container rollout.

Those legacy ECS / ECR app deploy roles are now disabled by default in this repo.

The business dev/prod app roles are the active ECS / ECR app deploy roles for this repo's future dev/prod path.

### MVP app deploy permissions

The MVP app deploy role for `telecom-dashboard/mw-dashboard-app` is separate from the Terraform roles and the older ECS / ECR app deploy roles.

It is limited to:
- `sts:GetCallerIdentity`
- `s3:ListBucket` on the MVP assets bucket
- `s3:GetObject`, `s3:PutObject`, `s3:DeleteObject` on the `releases/` prefix
- `ssm:SendCommand`
- `ssm:GetCommandInvocation`
- `ssm:ListCommandInvocations`
- `ssm:ListCommands`
- `ec2:DescribeInstances`

That role is for the current MVP deploy path:
- GitHub Actions in `telecom-dashboard/mw-dashboard-app`
- artifact upload to the existing MVP assets bucket under `releases/`
- SSM Run Command against the single MVP EC2 host by stable deploy tag

## Input

This root should be parameterized by the Terraform state bucket name and the MVP deploy targets.

The business dev/prod roles use:
- `infra_github_org`
- `infra_github_repo`
- `infra_github_branch`
- `aws_project_resource_prefix`

The future business app dev/prod roles use:
- `business_app_github_org`
- `business_app_github_repo`
- `business_app_github_branch`

Example:

```bash
terraform plan \
  -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET" \
  -var="mvp_assets_bucket_name=YOUR_MVP_ASSETS_BUCKET"
terraform apply \
  -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET" \
  -var="mvp_assets_bucket_name=YOUR_MVP_ASSETS_BUCKET"
```

That is better than hard-coding old account-specific S3 ARNs into policy documents.

## Relationship to GitHub repository variables

After applying this root, copy the resulting role ARNs into the repository variables used by GitHub Actions.

Expected repository variables:

- `AWS_REGION`
- `TF_STATE_BUCKET_NAME`
- `AWS_TERRAFORM_DEV_ROLE_ARN`
- `AWS_TERRAFORM_PROD_ROLE_ARN`
- `AWS_APP_ROLE_ARN` in the `dev` GitHub environment
- `AWS_APP_ROLE_ARN` in the `prod` GitHub environment
- `AWS_MVP_APP_DEPLOY_ROLE_ARN`

The legacy dev/prod role outputs will be `null` unless you explicitly enable them.

The business repo outputs are:
- `business_terraform_dev_role_arn`
- `business_terraform_prod_role_arn`
- `business_app_dev_role_arn`
- `business_app_prod_role_arn`

The current MVP EC2 deploy output is:
- `mvp_app_deploy_role_arn`

The workflows use these variables to:
- assume the correct Terraform or app deploy role
- select the correct AWS region
- inject the backend S3 bucket during `terraform init`
- authenticate the app deploy workflow for ECR / ECS operations
- authenticate the MVP app deploy workflow for S3 artifact upload and SSM Run Command

This keeps the workflows account-aware without hard-coding account-specific values into the workflow files.

## Commands

Run from this folder:

```bash
cd terraform/bootstrap/terraform-ci-roles
terraform init
terraform fmt -check
terraform validate
terraform plan \
  -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET" \
  -var="mvp_assets_bucket_name=YOUR_MVP_ASSETS_BUCKET"
```

Apply:

```bash
terraform apply \
  -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET" \
  -var="mvp_assets_bucket_name=YOUR_MVP_ASSETS_BUCKET"
```

## Why it is separate

This root is intentionally separate from `terraform/envs/*` because:
- CI roles are control-plane resources
- environment roots should assume CI roles already exist
- app deployment roles should exist before the first image push or deploy
- the MVP app deploy role should exist before `telecom-dashboard/mw-dashboard-app` tries to upload a release artifact or invoke SSM
- mixing IAM bootstrap and application infrastructure in one root becomes messy fast

## Important caution

A bad change here can break:
- GitHub Actions authentication
- Terraform plan/apply in CI
- remote state access
- app deployment to ECR / ECS
- app deployment to the MVP EC2 host
- both environments at once

## Relationship to the rest of the repo

- `bootstrap/oidc` enables GitHub OIDC
- `bootstrap/backend` creates the remote state bucket
- `bootstrap/terraform-ci-roles` gives Terraform CI and app deploy workflows the right roles and permissions
- `envs/dev` and `envs/prod` use those roles for the later ECS-oriented environments
- `envs/mvp` provides the stable deploy tag and assets bucket consumed by the MVP app deploy role
- `telecom-dashboard/mw-dashboard-app` uses the MVP app deploy role for S3 artifact upload and SSM Run Command
