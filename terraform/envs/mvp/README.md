# mvp environment

This folder is the Terraform root for the low-cost **mvp** environment.

It is intentionally separate from the existing ECS-oriented `dev` and `prod` roots.

## What mvp provisions

- VPC
- public subnet
- single EC2 app host
- Elastic IP
- Route 53 A record
- Nginx reverse proxy bootstrap
- frontend/static site on `/`
- backend reverse proxy on `/api`
- backend app runtime bootstrap placeholders on the same EC2 host
- PostgreSQL bootstrap on the same EC2 host
- S3 bucket for static files and assets
- basic CloudWatch alarms

## Why this root exists

The repo was copied from an ECS showcase, but the current business need is a cheap MVP.

Forcing the old `dev` ECS root to become the MVP would blur responsibilities and make the later ALB + ECS migration harder to reason about.

This root keeps the repo honest:
- `envs/mvp` is the current single-host path
- `envs/dev` and `envs/prod` stay available for the later ECS/ALB shape

## Backend note

The backend bucket is intentionally not hard-coded in `backend.tf`.

Example:

```bash
cd terraform/envs/mvp
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
terraform plan -var-file="mvp.tfvars"
```

## Domain

The MVP domain is:

```text
mvp.monitor.buildwithhein.com
```

Nginx is prepared for a same-domain app layout:
- `/` serves the frontend/static files
- `/api/` proxies to the backend app running on `127.0.0.1`

## Important MVP tradeoffs

- the database is on the same EC2 host as the app
- the app host is directly internet-facing
- there is no ALB
- there is no ECS
- there is no multi-AZ runtime layer

Those are intentional MVP cost and speed choices, not a claim that this is production-grade.
