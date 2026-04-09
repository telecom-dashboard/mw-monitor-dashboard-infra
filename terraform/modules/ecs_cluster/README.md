# ecs_cluster module

## Purpose

This module creates the ECS cluster used by the platform.

At the current project stage, this is cluster foundation only — not a complete service deployment layer.

---

## What It Creates

This module currently creates:

- one ECS cluster
- optional container insights setting

The cluster name follows the environment-aware naming pattern:

```text
<project_name>-<environment>-cluster
```

---

## Inputs

Key inputs include:

- `project_name`
- `environment`
- `enable_container_insights`
- `common_tags`

---

## Outputs

This module exposes:

- `cluster_id`
- `cluster_arn`
- `cluster_name`

---

## Current Phase Context

At the current stage, this module creates only the ECS cluster.

It does not yet create:

- task definitions
- ECS services
- capacity providers
- service discovery
- autoscaling configuration
- execution roles or task roles

Those will come in later phases.