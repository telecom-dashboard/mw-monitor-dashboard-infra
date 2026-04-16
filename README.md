# nw-monitor-dashboard-infra

Terraform infrastructure for the network monitoring dashboard SaaS.

## Current Direction

This repo is the working infrastructure repo for the business application.

Current active path:
- `terraform/envs/mvp` runs the live low-cost MVP on a single EC2 host
- Route 53 points the app domain at that host
- Nginx serves the frontend on `/` and proxies the backend on `/api`
- PostgreSQL currently runs on the same host
- S3 stores MVP release artifacts and app assets

Future path:
- `terraform/envs/dev` and `terraform/envs/prod` preserve the later ALB + ECS direction
- reusable ECS, ALB, VPC, and logging modules stay in the repo so the migration path remains clear

For the current deploy path, start with `terraform/envs/mvp/README.md`.

## Repo Boundaries

This repo owns infrastructure.

The application code and MVP deploy workflow live in the separate app repo:
- `telecom-dashboard/mw-dashboard-app`

That app repo currently:
- builds the frontend
- bundles frontend + backend release artifacts
- uploads the release to the MVP S3 bucket
- triggers SSM Run Command against the tagged MVP EC2 host

Cross-repo contract highlights:
- infra provides the EC2 host, DNS, Nginx, systemd service, S3 bucket, IAM roles, and deploy target tag
- app repo provides the release bundle, host-side deploy script, and runtime startup script

## Terraform Roots

Bootstrap roots:
- `terraform/bootstrap/oidc`
- `terraform/bootstrap/backend`
- `terraform/bootstrap/terraform-ci-roles`

Environment roots:
- `terraform/envs/mvp`
- `terraform/envs/dev`
- `terraform/envs/prod`

Do not run Terraform from:
- repo root
- `terraform/`
- `terraform/modules/*`

## Recommended Order

In a fresh AWS account, the normal order is:

1. `terraform/bootstrap/oidc`
2. `terraform/bootstrap/backend`
3. `terraform/bootstrap/terraform-ci-roles`
4. `terraform/envs/mvp`
5. `terraform/envs/dev` when you are ready for the ECS-based path
6. `terraform/envs/prod` when you are ready for the ECS-based path

## Remote State

The environment roots intentionally do not hardcode the backend bucket name in `backend.tf`.

Typical MVP init:

```bash
cd terraform/envs/mvp
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
terraform plan -var-file="mvp.tfvars"
```

Typical dev init:

```bash
cd terraform/envs/dev
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
terraform plan -var-file="dev.tfvars"
```

Typical prod init:

```bash
cd terraform/envs/prod
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
terraform plan -var-file="prod.tfvars"
```

## What Lives In This Repo

Reusable Terraform modules cover:
- VPC and networking
- ALB and ECS components for the future dev/prod path
- EC2 host and security group components for the MVP path
- CloudWatch logging and basic EC2 alarms
- S3 assets bucket support

The legacy `app/` folder is only a small Terraform test workload for the ECS-oriented roots. It is not the primary business application and it is not the current MVP deploy source of truth.

## MVP Notes

The MVP path is intentionally simple:
- single public EC2 host
- direct Nginx termination on the host
- same-domain frontend and API routing
- host-local PostgreSQL
- Let’s Encrypt on the host when HTTPS is enabled

That keeps cost and operational overhead low, but it is not the long-term production shape.

## Related Docs

- `terraform/envs/mvp/README.md`
- `terraform/bootstrap/README.md`
- `terraform/modules/README.md`
