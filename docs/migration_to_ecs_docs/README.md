# MW Dashboard Migration Pack

This document pack is tailored for the `mw-dashboard-app` and `mw-monitor-dashboard-infra` repositories.

## Why this pack exists

The current production shape is a low-cost MVP:

- single Ubuntu EC2 host
- Nginx serving `/` and proxying `/api`
- React + Vite frontend
- FastAPI backend
- PostgreSQL on the same host
- GitHub Actions -> S3 artifact upload -> SSM Run Command deploy
- Parameter Store for runtime secrets

The target direction is a staged move toward:

- ALB as stable public entry point
- ECS for the application runtime
- RDS PostgreSQL for managed database operations
- optional RDS Proxy for connection pooling and failover resilience
- stronger rollback, observability, and scaling posture

## Document map

1. `01-architecture-and-topology.md`
   - current topology
   - bridge topology
   - target topology
   - text diagrams
   - traffic and dependency flow

2. `02-migration-strategy.md`
   - phased migration plan
   - zero/minimum downtime strategy
   - database cutover patterns
   - migration decision points
   - acceptance criteria

3. `03-runbooks-and-sops.md`
   - pre-flight checklist
   - migration day SOP
   - rollback SOP
   - smoke test checklist
   - incident handling notes

4. `04-capacity-and-operations.md`
   - how ECS handles growth
   - how RDS handles growth
   - scaling bottlenecks
   - alarms, backup, DR, and operational guardrails

## Recommended migration order

Do **not** jump directly from "single EC2 everything" to "full prod ECS" in one big-bang cutover.

Recommended order:

1. Harden the MVP.
2. Introduce ALB as the stable public entry point.
3. Move PostgreSQL from EC2 to RDS with continuous replication and a short cutover window.
4. Move app runtime from EC2 to ECS.
5. Add autoscaling and connection pooling.
6. Optimize cost and resiliency after the first stable release.

## Core principle

App cutovers can be near-zero downtime.

Database cutovers are where the real risk lives.

Treat the database migration as the primary event and the ECS migration as the secondary event.

## Intended audience

- project owner
- infra engineer
- application owner
- on-call operator during cutover
