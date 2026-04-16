# terraform bootstrap

This folder contains the bootstrap Terraform roots for the project.

These roots create the shared control-plane pieces that the environment roots depend on.

## What lives here

`backend/`
- creates the persistent S3 bucket used for Terraform remote state

`oidc/`
- creates the GitHub Actions OIDC provider and bootstrap trust

`terraform-ci-roles/`
- creates the GitHub Actions IAM roles used by this infra repo
- creates the MVP app deploy role used by `telecom-dashboard/mw-dashboard-app`
- grants remote state access for Terraform CI
- grants ECS/ECR deploy access for the future dev/prod app path
- grants S3/SSM access for the current MVP EC2 deploy path

## Why this is separate

Bootstrap resources should exist before normal environment automation runs.

Keeping them separate avoids dependency loops like:
- CI needs roles before it can run Terraform
- Terraform needs the backend before it can use remote state
- the app deploy workflow needs its deploy role before it can upload artifacts or invoke SSM

## Recommended order

In a fresh AWS account, run:

```bash
cd terraform/bootstrap/oidc
terraform init
terraform plan
terraform apply
```

```bash
cd ../backend
terraform init
terraform plan -var="bucket_name=YOUR_TF_STATE_BUCKET"
terraform apply -var="bucket_name=YOUR_TF_STATE_BUCKET"
```

```bash
cd ../terraform-ci-roles
terraform init
terraform plan \
  -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET" \
  -var="mvp_assets_bucket_name=YOUR_MVP_ASSETS_BUCKET"
terraform apply \
  -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET" \
  -var="mvp_assets_bucket_name=YOUR_MVP_ASSETS_BUCKET"
```

Then continue with:
- `terraform/envs/mvp`
- `terraform/envs/dev` when you are ready for the ECS path
- `terraform/envs/prod` when you are ready for the ECS path

## GitHub variables fed by bootstrap

After applying `terraform-ci-roles`, update the GitHub variables used by workflows:

- `AWS_REGION`
- `TF_STATE_BUCKET_NAME`
- `AWS_TERRAFORM_DEV_ROLE_ARN`
- `AWS_TERRAFORM_PROD_ROLE_ARN`
- `AWS_APP_ROLE_ARN` in the `dev` environment when you use the future ECS path
- `AWS_APP_ROLE_ARN` in the `prod` environment when you use the future ECS path
- `AWS_MVP_APP_DEPLOY_ROLE_ARN`

## Important cautions

- these folders affect the account control plane
- bad changes here can break GitHub Actions authentication
- bad changes here can break Terraform remote state access
- bad changes here can break the MVP app deploy workflow
- bad changes here can break future dev/prod CI in one shot

Treat bootstrap changes more carefully than ordinary environment tuning.
