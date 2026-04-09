# alb module

## Purpose

This module creates the Application Load Balancer foundation for the platform.

At the current project stage, this is a basic ALB setup used to prepare for future ECS service attachment.

---

## What It Creates

This module currently creates:

- Application Load Balancer
- HTTP listener on port 80
- target group for the application port

The target group uses:

- `target_type = "ip"`
- HTTP health checks
- configurable health check path

---

## Inputs

Key inputs include:

- `name_prefix`
- `environment`
- `vpc_id`
- `public_subnet_ids`
- `alb_security_group_id`
- `app_port`
- `health_check_path`
- `common_tags`

---

## Outputs

This module exposes:

- `alb_arn`
- `alb_dns_name`
- `alb_zone_id`
- `target_group_arn`
- `http_listener_arn`

---

## Important Naming Note

ALB-related resources use a short configurable prefix through `name_prefix` instead of the full project name.

This is intentional.

Reason:

AWS load balancer and target group names have strict length limits, so using the full project name is not always safe.

The environment roots currently pass `alb_name_prefix` into this module to keep names short and predictable.

---

## Current Phase Context

At the current stage, this module provides a basic public HTTP ALB foundation.

It does **not** yet include:

- HTTPS listener
- ACM certificate integration
- Route 53 alias records
- path-based routing rules
- multiple target groups
- advanced listener rule management

Those are expected in later phases.