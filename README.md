# nw-monitor-dashboard-infra

This repository is now being used as a separate Terraform repo for the SaaS business infrastructure.

Current primary path:
- `terraform/envs/mvp` for the single-EC2 MVP
- Route 53 + Elastic IP + Nginx + backend app + PostgreSQL on one EC2 host
- S3 for static files and uploaded assets
- basic CloudWatch alarms

Future path:
- keep the existing ECS-oriented `terraform/envs/dev` and `terraform/envs/prod` roots for the later ALB + ECS migration
- keep existing ECS, ALB, and ECR modules rather than deleting them now

Read `terraform/envs/mvp/README.md` first for the active deployment path. Older ECS-oriented sections below are retained mainly as reference for the later migration path.

---

## What this repository currently contains

### Infrastructure and platform
- GitHub Actions OIDC authentication for AWS
- Separate Terraform CI roles for **dev** and **prod**
- Separate GitHub Actions app deploy roles for **dev** and **prod**
- Remote Terraform state in S3 for the environment roots
- Separate Terraform roots for **dev** and **prod**
- Reusable Terraform modules

### AWS resources currently modeled in Terraform
- VPC
- Public and private subnets
- Optional NAT gateway
- Security groups
- CloudWatch log group
- ECS cluster
- Application Load Balancer
- ECR repository
- ECS task execution role
- ECS task definition
- ECS service
- ACM / Route 53 resources in the environment roots when HTTPS is enabled

### Application code
- A small FastAPI sample app under `app/`
- A Dockerfile for containerizing the sample app

### CI/CD workflows
- Terraform format / validate / plan workflow for **dev** and **prod**
- Separate application build / push / deploy workflows for **dev** and **prod**

---

## What Phase 5 means in this repo

The design is intentionally split:

### Terraform pipeline
Terraform creates and updates the platform resources:

1. VPC and networking
2. ALB and security groups
3. ECS cluster
4. ECR repository
5. ECS task definition
6. ECS service
7. ACM certificate and Route 53 alias record when HTTPS is enabled

The ECS service is intentionally bootstrapped with **`desired_count = 0`** so infrastructure can be created safely even when the ECR repository is still empty.

### App pipeline
GitHub Actions handles runtime delivery:

1. build the sample app image from `./app`
2. tag it with `${{ github.sha }}`
3. push it to Amazon ECR
4. download the current ECS task definition
5. render the new image into the task definition
6. deploy the updated task definition to ECS
7. set the service desired count to `1`
8. wait for service stability

That split is cleaner than making Terraform pretend to be a container delivery system.

---

## Important current behavior about destroy

This repo currently manages **ECR inside each environment root**.

That means:

- destroying `terraform/envs/dev` also destroys the **dev ECR repository**
- destroying `terraform/envs/prod` also destroys the **prod ECR repository**
- image persistence across environment destroys is **not** guaranteed in the current design

So if you destroy dev today, do **not** assume ECR survives. It does not, because ECR is owned by the same Terraform root as the rest of the dev environment.

If you want ECR to persist across dev destroys later, move it into a separate persistent Terraform root.

---

## Why this design is safer

This repo is optimized for a practical workflow:

- **Terraform** owns infrastructure shape
- **GitHub Actions app deploy** owns image rollout
- your **office PC does not need Docker Desktop**
- you can recreate dev infrastructure with an empty ECR repo
- the first app deploy workflow run can populate ECR and start the service

That is the clean fix for the “Terraform recreated ECS but ECR was empty” problem.

---

## What is still not finished yet

This repo is **not** pretending to be a fully hardened production platform yet.

Things that still belong in later phases:
- tighter least-privilege scoping for app deploy permissions
- GitHub protected environments / approval gates for prod
- deeper observability, alarms, dashboards, and runbooks
- secrets management for real application configuration
- autoscaling policies and validation

That is normal. Good infrastructure is layered, not imagined into existence.

---

## Repository structure

```text
.
├── .github/
│   └── workflows/
│       ├── app-deploy.yml
│       └── terraform-ci.yml
├── app/
│   ├── app.py
│   ├── Dockerfile
│   └── requirements.txt
├── terraform/
│   ├── bootstrap/
│   │   ├── backend/
│   │   ├── oidc/
│   │   ├── terraform-ci-roles/
│   │   └── README.md
│   ├── envs/
│   │   ├── dev/
│   │   └── prod/
│   └── modules/
│       ├── alb/
│       ├── cloudwatch_logs/
│       ├── ecr/
│       ├── ecs_cluster/
│       ├── ecs_service/
│       ├── ecs_task_definition/
│       ├── ecs_task_execution_role/
│       ├── platform/
│       ├── security_groups/
│       └── vpc/
└── README.md
```

---

## Bootstrap vs environment roots

This repo uses multiple Terraform roots on purpose.

### Bootstrap roots
Run these only for account-level control-plane setup:

- `terraform/bootstrap/oidc`
- `terraform/bootstrap/backend`
- `terraform/bootstrap/terraform-ci-roles`

### Environment roots
Run these for environment infrastructure and ECS resources:

- `terraform/envs/dev`
- `terraform/envs/prod`

### Do not run Terraform from
- the repo root
- `terraform/`
- `terraform/modules/*`

Those are not deployable roots.

---

## Recommended execution order in a fresh AWS account

When standing up this repo in a new AWS account, use this order:

1. `terraform/bootstrap/oidc`
2. `terraform/bootstrap/backend`
3. `terraform/bootstrap/terraform-ci-roles`
4. `terraform/envs/dev`
5. `terraform/envs/prod`
6. run the app deploy workflow for **dev**
7. run the app deploy workflow for **prod** when you are ready

If you already have a GitHub OIDC provider in the account, import it instead of trying to create a duplicate one.

---

## Backend behavior

The environment backend configuration is intentionally split so the repo does **not** hard-code an AWS account-specific S3 bucket name inside `backend.tf`.

That means local usage should provide the bucket name at init time.

Example for **dev**:

```bash
cd terraform/envs/dev
terraform init -reconfigure \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="region=YOUR_AWS_REGION"
terraform plan -var-file="dev.tfvars"
```

Example for **prod**:

```bash
cd terraform/envs/prod
terraform init -reconfigure \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="region=YOUR_AWS_REGION"
terraform plan -var-file="prod.tfvars"
```

If you prefer, you can also supply the bucket through a local `.tfbackend` file that stays out of version control.

---

## Current CI/CD state

### Terraform CI
The committed workflow in `.github/workflows/terraform-ci.yml` handles Terraform CI for **dev** and **prod**:

- AWS credential setup through OIDC
- `terraform init`
- `terraform fmt -check`
- `terraform validate`
- `terraform plan`

### App deploy workflow
The committed application workflow in `.github/workflows/app-deploy.yml` handles:

- Docker image build on a GitHub-hosted runner
- Amazon ECR login
- image push to ECR with the `${{ github.sha }}` tag
- download of the current ECS task definition
- task definition rendering with the new image
- ECS service deployment
- service scale-up to `1`
- wait for service stability

Behavior:
- pushes to `main` with changes under `app/**` automatically deploy to **dev**
- manual `workflow_dispatch` can deploy either **dev** or **prod**

---

## GitHub Actions CI/CD configuration

This repo uses GitHub OIDC plus repository variables.

### Required GitHub repository variables

Set these under:

`Settings -> Secrets and variables -> Actions -> Variables`

Required variables:

- `AWS_REGION`
  Example: `ap-southeast-1`

- `TF_STATE_BUCKET_NAME`
  Example: `heinzawhtoo-tf-state-091234567891-apse1`

- `AWS_TERRAFORM_DEV_ROLE_ARN`
  ARN of the dev Terraform CI role created by `terraform/bootstrap/terraform-ci-roles`

- `AWS_TERRAFORM_PROD_ROLE_ARN`
  ARN of the prod Terraform CI role created by `terraform/bootstrap/terraform-ci-roles`

- `AWS_APP_ROLE_ARN` in the `dev` GitHub environment
  ARN of the dev app build/deploy role created by `terraform/bootstrap/terraform-ci-roles`

- `AWS_APP_ROLE_ARN` in the `prod` GitHub environment
  ARN of the prod app build/deploy role created by `terraform/bootstrap/terraform-ci-roles`

### Why the workflow injects backend config

The environment roots keep a backend skeleton in `backend.tf`, but the CI workflow injects the backend bucket during `terraform init`:

```bash
terraform init -input=false -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET_NAME}" \
  -backend-config="region=${AWS_REGION}"
```

This avoids hard-coding account-specific backend values into workflow logic and makes account migration much cleaner.

### Local vs CI behavior

- Local runs may still use backend config files or direct `-backend-config`
- CI does not rely on local developer files
- CI always uses the GitHub repository variables above
- app image builds happen in GitHub Actions, not on your local machine

---

## Environments

### Dev
Use dev for:
- iteration
- testing
- low-risk infrastructure changes
- cheaper experimentation

### Prod
Use prod for:
- production-style separation
- stricter review
- closer-to-real-world settings

Each environment has its own:
- Terraform root
- state key
- tfvars file
- IAM role used by Terraform CI
- IAM role used by app deployment

---

## App folder

The `app/` directory contains a small FastAPI app used as the sample ECS workload for this project.

It is intentionally simple:
- `/health` returns health and environment info
- `/api/cidr` calculates CIDR details
- `/` serves a tiny HTML UI

This keeps the repo focused on platform delivery while still having a real container target.

---

## Practical day-to-day commands

### Bootstrap IAM roles
```bash
cd terraform/bootstrap/terraform-ci-roles
terraform init
terraform fmt
terraform validate
terraform plan -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET"
terraform apply -var="tf_state_bucket_name=YOUR_TF_STATE_BUCKET"
```

### Dev infrastructure
```bash
cd terraform/envs/dev
terraform init -reconfigure \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="region=YOUR_AWS_REGION"
terraform fmt -check
terraform validate
terraform plan -var-file="dev.tfvars"
terraform apply -var-file="dev.tfvars"
```

Destroy dev infrastructure:
```bash
terraform destroy -var-file="dev.tfvars"
```

### Prod infrastructure
```bash
cd terraform/envs/prod
terraform init -reconfigure \
  -backend-config="bucket=YOUR_TF_STATE_BUCKET" \
  -backend-config="region=YOUR_AWS_REGION"
terraform fmt -check
terraform validate
terraform plan -var-file="prod.tfvars"
terraform apply -var-file="prod.tfvars"
```

Destroy prod infrastructure:
```bash
terraform destroy -var-file="prod.tfvars"
```

### First deploy after recreating dev
1. apply `terraform/envs/dev`
2. go to **Actions**
3. run **App Deploy**
4. choose `dev` if using manual dispatch
5. let GitHub Actions build, push, and deploy the image

That is the intended recovery path after destroying dev.

---

## Cost and safety guidance

- Keep the backend bucket persistent
- Keep bootstrap resources persistent unless you are intentionally rebuilding the control plane
- Do not assume ECR persists after destroying an environment root in the current design
- Destroy expensive runtime infrastructure when idle if this is still a showcase/lab environment
- Review prod plans more carefully than dev plans
- Keep prod deployment manual until later hardening phases
- Do not trust old README text after large Terraform refactors unless it has been refreshed

---

## Phase 5 direction

Strong next improvements after this patch would be:

- GitHub protected environments and approvals for prod
- CloudWatch alarms and autoscaling validation
- ECS Exec enablement and operational docs
- secrets injection through SSM Parameter Store or Secrets Manager
- move ECR into a separate persistent root if you want image persistence across dev destroys

That is where “works” starts turning into “solid”.
# Repo Direction

This repository is now being used as a separate Terraform repo for the SaaS business infrastructure.

Current primary path:
- `terraform/envs/mvp` for the single-EC2 MVP
- Route 53 + Elastic IP + Nginx + backend app + PostgreSQL on one EC2 host
- S3 for static files and uploaded assets
- basic CloudWatch alarms

Future path:
- keep the existing ECS-oriented `terraform/envs/dev` and `terraform/envs/prod` roots for the later ALB + ECS migration
- keep existing ECS, ALB, and ECR modules rather than deleting them now

Read `terraform/envs/mvp/README.md` first for the active deployment path. Older ECS-oriented sections below are retained mainly as reference for the later migration path.
