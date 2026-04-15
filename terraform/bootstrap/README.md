# terraform bootstrap

This folder contains the **bootstrap Terraform roots** for the project.

These roots are different from `terraform/envs/dev` and `terraform/envs/prod` because they build the **control plane** for the rest of the repo.

---

## What lives here

### `backend/`
Creates the persistent S3 bucket used for Terraform remote state.

### `oidc/`
Creates the GitHub Actions OIDC provider and the bootstrap IAM role trusted by GitHub Actions.

### `terraform-ci-roles/`
Creates the IAM roles used by GitHub Actions for this repo, including:

- Terraform CI role for **dev**
- Terraform CI role for **prod**
- app deploy role for **dev**
- app deploy role for **prod**
- MVP app deploy role for `telecom-dashboard/mw-dashboard-app`

It also grants:
- backend bucket access for Terraform CI
- infrastructure permissions for Terraform CI
- ECR / ECS deployment permissions for the app deploy workflow
- S3 / SSM permissions for the MVP EC2 deploy workflow

---

## Why this is separate

Bootstrap resources are foundational.

They should not be mixed into the environment roots because that creates ugly dependency loops like:

- CI needs roles before it can run Terraform
- Terraform needs backend before it can use remote state
- app deployment needs app roles before it can push to ECR and deploy ECS
- MVP app deployment needs its own role before GitHub Actions can upload release artifacts and invoke SSM
- environments need bootstrap in place before they are safe to use in CI

Keeping bootstrap separate avoids that nonsense.

---

## Recommended order

In a fresh AWS account, run bootstrap in this order:

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

Then move on to:

- `terraform/envs/dev`
- `terraform/envs/prod`
- the `App Deploy` GitHub Actions workflow

---

## Outputs you will care about

After applying `terraform-ci-roles`, the most useful outputs are:

- `terraform_dev_role_arn`
- `terraform_prod_role_arn`
- `app_dev_role_arn`
- `app_prod_role_arn`
- `mvp_app_deploy_role_arn`

These map directly to GitHub repository variables used by the workflows.

---

## GitHub repository variables that depend on bootstrap

After bootstrap is applied, update these repository variables:

- `AWS_REGION`
- `TF_STATE_BUCKET_NAME`
- `AWS_TERRAFORM_DEV_ROLE_ARN`
- `AWS_TERRAFORM_PROD_ROLE_ARN`
- `AWS_APP_ROLE_ARN` in the `dev` GitHub environment
- `AWS_APP_ROLE_ARN` in the `prod` GitHub environment
- `AWS_MVP_APP_DEPLOY_ROLE_ARN`

Without those, GitHub Actions cannot run the Terraform or app deployment workflows correctly.

---

## Important cautions

- These folders affect the account control plane
- bad changes here can break GitHub Actions authentication
- bad changes here can break Terraform remote state access
- bad changes here can break app deployment to ECR / ECS
- bad changes here can break app deployment to the MVP EC2 host
- bad changes here can break both dev and prod CI in one shot

Treat bootstrap changes with more care than normal environment tuning.

---

## What does **not** belong here

Do **not** edit bootstrap for:

- subnet CIDRs
- app port
- ALB ingress rules
- service desired count
- environment-specific tuning

That belongs under:

- `terraform/envs/dev`
- `terraform/envs/prod`

---

## State behavior

These bootstrap roots are intentionally separate from the environment backends.

In practice:

- `backend/` creates the persistent S3 bucket
- `envs/dev` and `envs/prod` use that bucket for remote state
- `terraform-ci-roles/` grants CI access to that bucket
- `oidc/` enables GitHub Actions to assume AWS roles securely

That layering is the whole point.
