# bootstrap terraform-ci-roles

This Terraform root creates the GitHub Actions roles for **dev** and **prod**.

---

## What it does

This root is responsible for:
- looking up the existing GitHub OIDC provider
- creating the Terraform CI IAM role for **dev**
- creating the Terraform CI IAM role for **prod**
- creating the app deploy IAM role for **dev**
- creating the app deploy IAM role for **prod**
- granting backend S3 bucket access for Terraform CI
- granting the AWS permissions needed for the current Terraform-managed infrastructure
- granting the ECR / ECS permissions needed for the app deploy workflow

---

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

### App deploy permissions
The app deploy roles need permissions related to:
- `ecr:GetAuthorizationToken`
- ECR layer upload and image push
- ECS task definition lookup and registration
- `iam:PassRole` for the ECS task execution role
- ECS service update and describe operations

That split lets Terraform own infrastructure while GitHub Actions owns container rollout.

---

## Input

This root should be parameterized by the Terraform state bucket name.

Example:
```bash
terraform plan -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET"
terraform apply -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET"
```

That is better than hard-coding old account-specific S3 ARNs into policy documents.

---

## Relationship to GitHub repository variables

After applying this root, copy the resulting role ARNs into the repository variables used by GitHub Actions.

Expected repository variables:

- `AWS_REGION`
- `TF_STATE_BUCKET_NAME`
- `AWS_TERRAFORM_DEV_ROLE_ARN`
- `AWS_TERRAFORM_PROD_ROLE_ARN`
- `AWS_APP_ROLE_ARN` in the `dev` GitHub environment
- `AWS_APP_ROLE_ARN` in the `prod` GitHub environment

The workflows use these variables to:
- assume the correct Terraform or app deploy role
- select the correct AWS region
- inject the backend S3 bucket during `terraform init`
- authenticate the app deploy workflow for ECR / ECS operations

This keeps the workflows account-aware without hard-coding account-specific values into the workflow files.

---

## Commands

Run from this folder:

```bash
cd terraform/bootstrap/terraform-ci-roles
terraform init
terraform fmt -check
terraform validate
terraform plan -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET"
```

Apply:
```bash
terraform apply -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET"
```

---

## Why it is separate

This root is intentionally separate from `terraform/envs/*` because:
- CI roles are control-plane resources
- environment roots should assume CI roles already exist
- app deployment roles should exist before the first image push / deploy
- mixing IAM bootstrap and application infrastructure in one root becomes messy fast

---

## Important caution

A bad change here can break:
- GitHub Actions authentication
- Terraform plan/apply in CI
- remote state access
- app deployment to ECR / ECS
- both environments at once

So yes, this folder deserves paranoia.

---

## Relationship to the rest of the repo

- `bootstrap/oidc` enables GitHub OIDC
- `bootstrap/backend` creates the remote state bucket
- `bootstrap/terraform-ci-roles` gives Terraform CI and app deploy workflows the right roles and permissions
- `envs/dev` and `envs/prod` use those roles to manage infrastructure
- `.github/workflows/app-deploy.yml` uses the app roles to push images and deploy ECS
