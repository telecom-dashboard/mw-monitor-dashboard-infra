# cloudwatch_logs module

## Purpose

This module creates the CloudWatch Logs resources used by the current platform foundation for ECS application logging.

---

## What It Creates

This module currently creates:

- one CloudWatch log group for ECS application logs

The log group name follows the environment-aware naming pattern:

```text
/aws/ecs/<project_name>-<environment>-app
```

---

## Inputs

Key inputs include:

- `project_name`
- `environment`
- `retention_in_days`
- `common_tags`

---

## Outputs

This module exposes:

- `ecs_app_log_group_name`
- `ecs_app_log_group_arn`

---

## Current Phase Context

At the current stage, this module provides the log group foundation only.

It does **not** yet configure:

- ECS task log configuration
- metric filters
- alarms
- subscription filters
- centralized observability pipelines

Those are expected to be added in later phases as the runtime layer becomes real.