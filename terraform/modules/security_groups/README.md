# security_groups module

## Purpose

This module creates the security groups used by the current Phase 3 platform foundation.

It focuses on the traffic flow between the ALB and future ECS tasks.

---

## What It Creates

This module creates:

- ALB security group
- ECS tasks security group

### Current traffic model

- ALB allows inbound HTTP from the configured CIDR blocks
- ECS tasks allow inbound application traffic only from the ALB security group
- both security groups allow outbound traffic

---

## Inputs

Key inputs include:

- `project_name`
- `environment`
- `vpc_id`
- `app_port`
- `alb_ingress_cidr_blocks`
- `common_tags`

---

## Outputs

This module exposes:

- `alb_security_group_id`
- `ecs_tasks_security_group_id`

---

## Current Phase Context

At the current stage, this module supports a basic ALB-to-application traffic pattern.

It does **not** yet include more advanced controls such as:

- HTTPS listener-specific policy behavior
- additional internal-only service groups
- database access patterns
- tighter egress controls
- service-to-service security models

Those can be added later as the platform grows.

---

## Operational Note

If you are changing which clients can reach the ALB, update the CIDR inputs in the environment root rather than hardcoding environment-specific behavior in this module.