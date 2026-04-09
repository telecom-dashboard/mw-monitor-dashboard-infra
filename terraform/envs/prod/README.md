# prod environment

This folder is the Terraform root for the **prod** environment.

It composes the shared modules under `terraform/modules` to create the production-style platform and ECS application stack.

---

## What prod currently provisions

At the current repo state, prod includes:
- VPC
- public and private subnets
- internet gateway
- NAT gateway support
- security groups
- CloudWatch log group
- ECS cluster
- ALB and target group
- ECR repository
- ECS task execution role
- ECS task definition
- ECS service

So prod is also beyond the old “Phase 3 platform only” description.

---

## Key files

- `backend.tf` — backend skeleton for the prod state key
- `providers.tf` — provider configuration
- `locals.tf` — shared local values and common tags
- `main.tf` — composes the prod stack
- `variables.tf` — environment inputs
- `outputs.tf` — useful outputs
- `prod.tfvars` — concrete prod values
- `prod.tfvars.example` — example values for bootstrapping or sharing structure

---

## Backend note

The backend bucket is intentionally **not** hard-coded in `backend.tf`.

That means you should provide the bucket during init.

Example:
```bash
cd terraform/envs/prod
terraform init -reconfigure -backend-config="bucket=YOUR_TF_STATE_BUCKET"
```

Then run:
```bash
terraform fmt -check
terraform validate
terraform plan -var-file="prod.tfvars"
```

Apply:
```bash
terraform apply -var-file="prod.tfvars"
```

Destroy:
```bash
terraform destroy -var-file="prod.tfvars"
```

If you prefer, you can use a local `.tfbackend` file instead of putting the bucket value on the command line.

---

## What to edit here

Edit this folder when you want to change prod-specific settings such as:
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
- naming prefixes

If the change should affect both environments, change the shared module instead.

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

## Safety posture

Prod should be treated more carefully than dev.

Recommended habit:
1. plan locally first
2. review the diff carefully
3. apply dev first if the change touches shared modules
4. apply prod only after the behavior is understood

That habit saves pain.

---

## Outputs you should expect

Typical useful outputs from this environment include:
- VPC details
- subnet IDs
- ALB details
- ECS cluster details
- ECR repository details
- ECS service / task-related outputs where exposed
