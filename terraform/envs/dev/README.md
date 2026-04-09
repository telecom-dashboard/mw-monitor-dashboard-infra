# dev environment

This folder is the Terraform root for the **dev** environment.

It composes the shared modules under `terraform/modules` to create the dev platform and ECS application stack.

---

## What dev currently provisions

At the current repo state, dev includes:
- VPC
- public and private subnets
- internet gateway
- optional NAT gateway
- security groups
- CloudWatch log group
- ECS cluster
- ALB and target group
- ECR repository
- ECS task execution role
- ECS task definition
- ECS service

That means dev is no longer just “Phase 3 base platform only”.

---

## Key files

- `backend.tf` — backend skeleton for the dev state key
- `providers.tf` — provider configuration
- `locals.tf` — shared local values and common tags
- `main.tf` — composes the dev stack
- `variables.tf` — environment inputs
- `outputs.tf` — useful outputs
- `dev.tfvars` — concrete dev values
- `dev.tfvars.example` — example values for bootstrapping or sharing structure

---

## Backend note

The backend bucket is intentionally **not** hard-coded in `backend.tf`.

That means you should provide the bucket during init.

Example:
```bash
cd terraform/envs/dev
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
```

Then run:
```bash
terraform fmt -check
terraform validate
terraform plan -var-file="dev.tfvars"
```

Apply:
```bash
terraform apply -var-file="dev.tfvars"
```

Destroy:
```bash
terraform destroy -var-file="dev.tfvars"
```

If you prefer, you can store the bucket value in a local `.tfbackend` file that is not committed.

---

## What to edit here

Edit this folder when you want to change dev-specific settings such as:
- CIDR ranges
- availability zones
- NAT behavior
- ALB ingress CIDRs
- app port
- health check path
- task CPU and memory
- desired ECS service count
- log retention
- container environment variables
- ECR force delete behavior
- short naming prefixes

If the change should affect both environments, edit the shared module instead.

---

## CI backend behavior

In GitHub Actions, the backend bucket is injected during `terraform init` using repository variables.

Example:

```bash
terraform init -input=false -reconfigure \
  -backend-config="bucket=${TF_STATE_BUCKET_NAME}" \
  -backend-config="region=${AWS_REGION}"
```
This means CI does not depend on a developer's local backend file contents.

---

## Cost posture

Dev is the place to be cheaper and faster to iterate.

Typical dev choices can include:
- fewer desired tasks
- looser cost controls
- NAT disabled when acceptable
- shorter-lived infrastructure

Just be explicit about those tradeoffs so the repo stays honest.

---

## Outputs you should expect

Typical useful outputs from this environment include:
- VPC details
- subnet IDs
- ALB details
- ECS cluster details
- ECR repository details
- ECS service / task-related outputs where exposed

Use outputs for integration, not guesswork.
