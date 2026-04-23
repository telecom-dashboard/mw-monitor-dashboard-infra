# MVP Architecture

This document describes the current MVP topology, how the infra repo and app repo work together, and which files are responsible at each stage of the system lifecycle.

## Repos

Current repos:
- infra repo: `nw-monitor-dashboard-infra`
- app repo: `telecom-dashboard/mw-dashboard-app`

Ownership split:
- infra repo owns AWS infrastructure, EC2 bootstrap, DNS, IAM, S3, and deployment plumbing
- app repo owns frontend code, backend code, release packaging, and the GitHub Actions deploy workflow

## Topology

Current MVP runtime topology:

```text
Internet
  |
  v
Route 53 DNS
  |
  v
Elastic IP
  |
  v
EC2 Host (Ubuntu)
  |
  +-- Nginx
  |     |
  |     +-- "/"      -> static frontend files in /var/www/app
  |     |
  |     +-- "/api/"  -> reverse proxy to backend on 127.0.0.1:${app_port}
  |
  +-- systemd service: saas-app
  |     |
  |     +-- start.sh
  |            |
  |            +-- loads /opt/app/shared/backend.env
  |            +-- fetches secrets from SSM Parameter Store
  |            +-- starts uvicorn from the backend virtualenv
  |
  +-- PostgreSQL
        |
        +-- app database on the same host
```

Current deploy topology:

```text
GitHub Actions (app repo)
  |
  +-- assume MVP deploy IAM role via GitHub OIDC
  |
  +-- upload release bundle to S3
  |
  +-- resolve target EC2 host by tag:
  |      DeployTarget=nw-monitor-dashboard-mvp-app-host
  |
  +-- send SSM Run Command
         |
         v
       EC2 host
         |
         +-- downloads release bundle from S3
         +-- updates frontend and backend files
         +-- restarts saas-app
```

## Terraform Topology

Current Terraform root structure:

```text
terraform/
  bootstrap/
    oidc/
    backend/
    terraform-ci-roles/
  envs/
    mvp/
    dev/
    prod/
  modules/
    ec2_host/
    ec2_security_group/
    cloudwatch_ec2_basic/
    s3_assets_bucket/
    vpc/
    ...
```

Meaning:
- `bootstrap/*` creates shared control-plane resources
- `envs/mvp` creates the active MVP infrastructure
- `envs/dev` and `envs/prod` preserve the later ECS/ALB direction
- `modules/*` contains reusable building blocks

## Lifecycle Stages

There are four main stages.

### 1. Bootstrap stage

Purpose:
- create shared control-plane resources before normal environment deploys

Main files and roots:
- [terraform/bootstrap/oidc/README.md](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/oidc/README.md:1)
- [terraform/bootstrap/backend/README.md](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/backend/README.md:1)
- [terraform/bootstrap/terraform-ci-roles/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/terraform-ci-roles/main.tf:1)

What happens:
- OIDC trust is created for GitHub Actions
- Terraform remote state bucket is created
- GitHub Actions IAM roles are created
- MVP app deploy IAM role is created for the app repo

### 2. Infrastructure stage

Purpose:
- provision and update the live MVP infrastructure

Main files:
- [terraform/envs/mvp/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/main.tf:1)
- [terraform/envs/mvp/variables.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/variables.tf:1)
- [terraform/envs/mvp/mvp.tfvars](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/mvp.tfvars:1)
- [terraform/envs/mvp/user_data.sh.tftpl](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/user_data.sh.tftpl:1)

What happens:
- VPC, subnet, security group, EC2 host, EIP, Route 53 record, S3 bucket, and alarms are managed
- the EC2 host is bootstrapped into a working app server
- the stable deploy tag is attached to the EC2 instance

Important behavior:
- the EC2 module uses `user_data_replace_on_change = true`
- if user data changes, `terraform apply` can replace the instance

### 3. App deploy stage

Purpose:
- publish a new application release onto the live EC2 host

Main app repo files:
- `mw-dashboard-app/.github/workflows/deploy.yml`
- `mw-dashboard-app/deploy.sh`

What happens:
- frontend is built
- frontend, backend, and `start.sh` are bundled
- release artifact is uploaded to S3
- GitHub Actions resolves the EC2 target by tag
- GitHub Actions sends SSM Run Command
- the host downloads and installs the release

### 4. Runtime stage

Purpose:
- keep the backend process running continuously on the host

Main files:
- [terraform/envs/mvp/user_data.sh.tftpl](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/user_data.sh.tftpl:1)
- `mw-dashboard-app/start.sh`

What happens:
- systemd starts `saas-app`
- `start.sh` loads env, fetches secrets, and launches Uvicorn
- Nginx serves frontend and proxies API requests

## Infra Repo Wiring

The active MVP composition happens in [terraform/envs/mvp/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/main.tf:1).

High-level module wiring:

```text
envs/mvp/main.tf
  |
  +-- module.vpc
  +-- module.ec2_security_group
  +-- module.assets_bucket
  +-- module.ec2_host
  +-- module.cloudwatch_ec2_basic
  +-- aws_route53_record.app
```

Important responsibilities:
- `module.vpc` creates the MVP network base
- `module.ec2_security_group` opens HTTP and HTTPS ingress
- `module.assets_bucket` stores release artifacts and app assets
- `module.ec2_host` creates the EC2 host, IAM role, EIP, and user data bootstrap
- `aws_route53_record.app` points the public app domain to the host

## EC2 Bootstrap Wiring

The EC2 bootstrap script is [terraform/envs/mvp/user_data.sh.tftpl](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/user_data.sh.tftpl:1).

It is responsible for converting a plain Ubuntu host into the MVP app server.

Bootstrap responsibilities:
- install core packages
- install AWS CLI
- install and configure Nginx
- optionally install and configure HTTPS with Certbot
- create `/var/www/app`
- create `/opt/app/current`
- create `/opt/app/shared`
- create the `saas-app` systemd unit
- install and initialize PostgreSQL
- configure Nginx routing for `/` and `/api`

Text topology of the host filesystem:

```text
/var/www/app
  -> frontend static files served by Nginx

/opt/app/current
  -> current deployed application release

/opt/app/current/backend
  -> backend code from the app repo

/opt/app/current/start.sh
  -> runtime startup script from the app repo

/opt/app/shared/backend.env
  -> non-secret runtime environment values such as DB_HOST, DB_PORT, DB_NAME, and DB_USER
```

## IAM and SSM Wiring

The MVP deploy IAM role is created in [terraform/bootstrap/terraform-ci-roles/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/terraform-ci-roles/main.tf:1862).

That role is trusted by GitHub Actions from:
- `telecom-dashboard/mw-dashboard-app`

It is allowed to:
- upload release artifacts to the MVP S3 bucket
- call `ssm:SendCommand`
- read SSM invocation status
- describe EC2 instances

The EC2 instance role is created through the EC2 module and is allowed to:
- read from the MVP assets bucket
- read required SSM Parameter Store values
- use SSM as a managed instance

Current target-selection model:

```text
GitHub Actions
  -> ec2:DescribeInstances
  -> find running instance with tag:
       DeployTarget=nw-monitor-dashboard-mvp-app-host
  -> ssm:SendCommand to that tagged host
```

This avoids hard-coding a specific EC2 instance ID in the deploy workflow.

## App Repo Wiring

Main app repo responsibilities:
- build frontend assets
- package frontend + backend + `start.sh`
- upload release bundle
- send SSM Run Command
- install backend Python dependencies on-host
- restart the backend service

Important app repo files:

```text
.github/workflows/deploy.yml
  -> GitHub Actions deploy workflow

deploy.sh
  -> host-side deploy script run through SSM

start.sh
  -> runtime startup script run by systemd

frontend/
  -> React app built into static files

backend/
  -> FastAPI application code
```

Deploy-time text flow:

```text
GitHub Actions
  -> build frontend
  -> bundle release
  -> upload release to S3
  -> resolve EC2 target by tag
  -> send SSM Run Command
  -> host runs deploy.sh
       -> download release
       -> extract release
       -> copy frontend to /var/www/app
       -> copy backend to /opt/app/current/backend
       -> copy start.sh to /opt/app/current/start.sh
       -> create/update virtualenv
       -> install Python dependencies
       -> restart saas-app
```

Runtime text flow:

```text
systemd
  -> saas-app
       -> /opt/app/current/start.sh
            -> load /opt/app/shared/backend.env
            -> fetch SECRET_KEY from SSM Parameter Store
            -> fetch DB_PASSWORD from SSM Parameter Store
            -> build DATABASE_URL at runtime from DB_HOST, DB_PORT, DB_NAME, DB_USER, and DB_PASSWORD
            -> start uvicorn app.main:app
```

## Request Flow

Normal user request path:

```text
Browser
  -> Route 53 DNS
  -> Elastic IP
  -> Nginx on EC2
       -> "/"     serves frontend files
       -> "/api/" proxies to backend on localhost
            -> backend talks to local PostgreSQL
```

## File Responsibility By Stage

### Bootstrap

Infra repo:
- [terraform/bootstrap/oidc/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/oidc/main.tf:1)
- [terraform/bootstrap/backend/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/backend/main.tf:1)
- [terraform/bootstrap/terraform-ci-roles/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/bootstrap/terraform-ci-roles/main.tf:1)

### Infra apply

Infra repo:
- [terraform/envs/mvp/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/main.tf:1)
- [terraform/envs/mvp/variables.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/variables.tf:1)
- [terraform/envs/mvp/mvp.tfvars](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/mvp.tfvars:1)
- [terraform/envs/mvp/user_data.sh.tftpl](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/user_data.sh.tftpl:1)
- [terraform/modules/ec2_host/main.tf](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/modules/ec2_host/main.tf:1)

### App deploy

App repo:
- `mw-dashboard-app/.github/workflows/deploy.yml`
- `mw-dashboard-app/deploy.sh`

### Runtime

App repo:
- `mw-dashboard-app/start.sh`
- `mw-dashboard-app/backend/*`
- `mw-dashboard-app/frontend/dist/*`

Infra repo:
- [terraform/envs/mvp/user_data.sh.tftpl](/d:/GitHub%20Projects/nw-monitor-dashboard-infra/terraform/envs/mvp/user_data.sh.tftpl:1)

## Cross-Repo Contract

These values and conventions must stay aligned across both repos.

Deploy target:
- `DeployTarget=nw-monitor-dashboard-mvp-app-host`

Service name:
- `saas-app`

Host paths:
- `/var/www/app`
- `/opt/app/current`
- `/opt/app/current/backend`
- `/opt/app/current/start.sh`
- `/opt/app/shared/backend.env`

Parameter Store paths:
- `/nw-monitor/mvp/backend/secret_key`
- `/nw-monitor/mvp/backend/db_password`

Public routing:
- `/` for frontend
- `/api/` for backend

If any of these change in the infra repo, the app repo usually needs a matching update.

## Common Failure Modes

Common breakpoints in this MVP shape:
- EC2 replacement after `user_data` changes
- stale IAM permissions for deploy workflow changes
- Nginx bootstrap issues
- SSM-managed instance not online
- missing SSM parameters
- app repo deploy script drifting from infra host paths or service name

## Future Direction

This document describes the current MVP shape only.

The repo still keeps `envs/dev` and `envs/prod` plus ECS-related modules so the system can evolve later toward:
- ALB
- ECS
- cleaner environment separation
- more production-grade runtime patterns
