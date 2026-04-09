# vpc module

## Purpose

This module creates the base networking foundation for an environment.

It is responsible for building the VPC and subnet layout that the rest of the platform depends on.

---

## What It Creates

This module creates:

- VPC
- Internet Gateway
- public subnets
- private subnets
- public route table
- private route tables
- route table associations
- optional NAT gateway
- optional Elastic IP for NAT
- default public internet route
- default private NAT routes when NAT is enabled

---

## Inputs

Key inputs include:

- `project_name`
- `environment`
- `vpc_cidr`
- `availability_zones`
- `public_subnet_cidrs`
- `private_subnet_cidrs`
- `enable_nat_gateway`
- `common_tags`

---

## Outputs

This module exposes outputs including:

- `vpc_id`
- `vpc_cidr_block`
- `public_subnet_ids`
- `private_subnet_ids`
- `internet_gateway_id`
- `nat_gateway_id`
- `public_route_table_id`
- `private_route_table_ids`

---

## Important Behavior

### NAT gateway is optional

This module creates NAT-related resources only when:

```hcl
enable_nat_gateway = true
```

When NAT is disabled:

- no NAT gateway is created
- no NAT Elastic IP is created
- private route tables do not get a default route to NAT

That behavior is currently used by the dev environment for cost control.

---

## Module Boundary

This module is responsible for network foundation only.

It does not create:

- security groups
- ALB
- ECS cluster
- logging resources
- ECS services or task definitions

Those belong in other modules.