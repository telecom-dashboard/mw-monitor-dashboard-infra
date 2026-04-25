# mvp environment

This folder is the Terraform root for the current low-cost MVP environment.

It stays separate from `terraform/envs/dev` and `terraform/envs/prod` so the single-host MVP path is clear and the later ALB + ECS migration path stays clean.

## What mvp provisions

- VPC
- public subnet
- single EC2 app host
- Elastic IP
- Route 53 A record
- Nginx reverse proxy bootstrap
- frontend/static site on `/`
- backend reverse proxy on `/api`
- optional HTTPS on the EC2 host using Nginx + Let's Encrypt
- backend runtime bootstrap on the same EC2 host
- PostgreSQL bootstrap on the same EC2 host
- infra-owned `/opt/app/shared/backend.env` seeded with MVP runtime defaults
- S3 bucket for static files, uploaded assets, and MVP release artifacts
- basic CloudWatch alarms

## Backend note

The backend bucket is intentionally not hard-coded in `backend.tf`.

Example:

```bash
cd terraform/envs/mvp
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
terraform plan -var-file="mvp.tfvars"
```

## Domain and routing

The current MVP domain is:

```text
demo.monitor.buildwithhein.com
```

Nginx is prepared for a same-domain app layout:
- `/` serves the frontend/static files
- `/api/` proxies to the backend app running on `127.0.0.1` without stripping the `/api` prefix
- the generated MVP Nginx config allows request bodies up to `20m` and extends `/api/` proxy read/send timeouts to `300s` for Excel import flows

When `enable_https = true`, the EC2 host bootstraps Certbot, provisions a Let's Encrypt certificate for the MVP domain, redirects HTTP to HTTPS, and enables automatic renewal via `certbot.timer`.

## App deploy path

The current MVP deployment flow depends on the separate app repo:
- GitHub Actions in `telecom-dashboard/mw-dashboard-app`
- GitHub OIDC into the dedicated MVP app deploy IAM role
- artifact upload to the MVP assets bucket under `releases/`
- SSM Run Command against the single MVP EC2 host using the stable deploy tag `DeployTarget=nw-monitor-dashboard-mvp-app-host`

On first boot, the infra bootstrap creates `/opt/app/shared/backend.env` with the MVP host's DB and public URL settings. The app repo deploy reuses that file if it already exists, which keeps destroy-and-rebuild flows aligned without requiring the app repo's sample `.env` defaults to match MVP.

The EC2 bootstrap also reads `/nw-monitor/mvp/backend/db_password` from SSM Parameter Store before it creates or updates the local PostgreSQL role. That keeps the host's database password aligned with the same secret the app runtime fetches later.

This MVP path intentionally does **not** use ECS or ECR.

## Important MVP tradeoffs

- the database is on the same EC2 host as the app
- the app host is directly internet-facing
- there is no ALB
- there is no ECS
- there is no multi-AZ runtime layer

Those are intentional MVP cost and speed choices, not a claim that this is production-grade.
