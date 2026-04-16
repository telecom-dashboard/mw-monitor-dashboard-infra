# terraform modules

This folder contains the reusable Terraform building blocks used by the environment roots:

- `terraform/envs/dev`
- `terraform/envs/mvp`
- `terraform/envs/prod`

The goal is to keep environment roots thin and keep shared infrastructure logic in one place.

---

## Current modules

### `vpc`
Creates:
- VPC
- public subnets
- private subnets
- internet gateway
- optional NAT gateway
- route tables and associations

### `security_groups`
Creates:
- ALB security group
- ECS tasks security group

### `cloudwatch_logs`
Creates the application log group used by ECS.

### `cloudwatch_ec2_basic`
Creates basic CloudWatch alarms for the single EC2 MVP host.

### `ec2_security_group`
Creates the public security group for the single EC2 MVP host.

### `ec2_host`
Creates the EC2 instance, Elastic IP, and host IAM profile used by the MVP environment.

### `ecs_cluster`
Creates the ECS cluster and container insights settings.

### `alb`
Creates:
- Application Load Balancer
- listener
- target group

### `ecr`
Creates the ECR repository used by the future ECS-based application image.

### `ecs_task_execution_role`
Creates the execution role used by ECS tasks.

### `ecs_task_definition`
Creates the ECS task definition for the container workload.

### `ecs_service`
Creates the ECS service that registers tasks behind the target group.

### `platform`
Reserved for higher-level composition or future shared orchestration patterns.

### `s3_assets_bucket`
Creates the S3 bucket used for static files and uploaded assets in the MVP environment.

---

## Design rules

Modules here should be:
- reusable
- environment-agnostic
- focused on one job
- free of hard-coded dev/prod values whenever possible

Environment-specific settings belong in:
- `terraform/envs/mvp`
- `terraform/envs/dev`
- `terraform/envs/prod`
- per-environment tfvars files

---

## What belongs here

Good candidates:
- shared network logic
- shared logging logic
- shared EC2 host logic
- shared load balancing logic
- shared container platform logic
- shared ECS and ECR logic
- shared storage logic

---

## What does not belong here

Avoid putting these in modules unless there is a very good reason:
- backend configuration
- GitHub Actions workflow logic
- account bootstrap IAM/OIDC setup
- repo-specific CI variable names
- one-off manual migration hacks

That stuff belongs elsewhere.

---

## Usage pattern

The intended pattern is:

1. define reusable logic here
2. wire modules together in `envs/mvp`, `envs/dev`, and `envs/prod`
3. keep environment values in tfvars
4. expose useful outputs from the environment roots

That keeps the repo easier to maintain and easier to explain to the next human.
