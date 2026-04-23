# Architecture and Topology

## 1. Current state

This is the current MVP shape inferred from the repositories.

```text
Users
  |
  v
Route 53
  |
  v
Public DNS: mvp.monitor.buildwithhein.com
  |
  v
Elastic IP
  |
  v
+---------------------------------------------------------+
| Ubuntu EC2 Host                                         |
|---------------------------------------------------------|
| Nginx                                                   |
|  - serves frontend on /                                 |
|  - proxies /api to FastAPI on localhost                 |
|                                                         |
| FastAPI backend (systemd service: saas-app)             |
|  - started by start.sh                                  |
|  - deploys via deploy.sh                                |
|                                                         |
| PostgreSQL                                              |
|  - same host as app                                     |
|                                                         |
| Shared dirs                                             |
|  - /var/www/app                                         |
|  - /opt/app/current                                     |
|  - /opt/app/shared                                      |
+---------------------------------------------------------+
  ^                         ^
  |                         |
  |                         +---------------------------+
  |                                                     |
  |                                  Parameter Store    |
  |                                  - SECRET_KEY       |
  |                                  - DB_PASSWORD      |
  |                                                     |
  +----------- GitHub Actions --------------------------+
               - build frontend
               - bundle release
               - upload to S3
               - trigger SSM Run Command

S3
- release artifacts
- uploaded assets
```

## 2. Strengths of the current MVP

- very low cost
- simple mental model
- fast to deploy
- easy to debug because everything is on one host
- excellent learning value
- good fit for first real production responsibility

## 3. Weaknesses of the current MVP

- app, proxy, and database share one blast radius
- database and app fail together
- host failure impacts the entire stack
- scaling is mostly vertical
- rollback is limited by host state and shared components
- OS/package drift can quietly accumulate
- database operations are fully your responsibility

## 4. Bridge topology

This is the best intermediate state before a full ECS cutover.

```text
Users
  |
  v
Route 53
  |
  v
Application Load Balancer
  |
  +----------------------------+
  |                            |
  v                            v
Target Group A                Future Target Group B
(current EC2)                 (ECS service later)

Current EC2 remains alive behind the ALB:
- Nginx
- FastAPI
- local PostgreSQL initially
- existing GitHub Actions + SSM deploy flow
```

### Why the bridge topology matters

The ALB becomes the **stable public entry point**.

That means later changes can happen behind the ALB without changing the public DNS design every time.

Benefits:

- cleaner cutover path
- easier blue/green traffic shift later
- easier rollback path
- reusable health checks
- safer migration from EC2 target group to ECS target group

## 5. Target topology

This is the recommended grown-up target state.

```text
Users
  |
  v
Route 53
  |
  v
Application Load Balancer
  |
  +-------------------------------+
  |                               |
  v                               v
/                                 /api
Frontend delivery                 Backend service
(static or containerized)         ECS Service
                                  |
                                  v
                            ECS Tasks in private subnets
                                  |
                                  v
                              RDS Proxy (optional but recommended)
                                  |
                                  v
                             Amazon RDS PostgreSQL
```

Supporting components:

```text
GitHub Actions / CI
  -> build container image
  -> push to ECR
  -> deploy ECS service
  -> optionally perform blue/green deployment

CloudWatch
  - ALB 4xx/5xx alarms
  - target response time
  - ECS CPU/memory
  - task restarts
  - RDS CPU, free storage, connections, lag
  - synthetic health checks

Secrets / config
  - SSM Parameter Store and/or Secrets Manager

Artifacts / state
  - S3 for Terraform state and deployment artifacts
```

## 6. Recommended production traffic design

### Option A — keep same-domain routing

```text
https://monitor.example.com/       -> frontend
https://monitor.example.com/api    -> backend
```

Pros:
- frontend does not need CORS complexity
- easy mental model
- aligns with the current MVP contract

Cons:
- frontend serving strategy must be chosen carefully in ECS era

### Option B — split frontend and backend delivery later

```text
https://monitor.example.com/       -> S3/CloudFront frontend
https://api.monitor.example.com/   -> ALB -> ECS backend
```

Pros:
- frontend becomes simpler and cheaper to serve
- backend scaling and deploys become more independent

Cons:
- more DNS and CORS decisions
- bigger migration scope

### Practical recommendation

Keep **Option A first** during migration to reduce moving parts.
Revisit frontend separation only after ECS + RDS is stable.

## 7. Dependency flow

```text
GitHub push
  -> CI build
  -> artifact or image publish
  -> deploy trigger
  -> app boot
  -> secrets fetch
  -> DB connect
  -> health check pass
  -> traffic shift
```

## 8. Non-functional requirements for the migration

The migration should satisfy these outcomes:

- no data loss
- minimum downtime for write traffic
- fast rollback
- measurable health before cutover
- repeatable deploy steps
- no manual heroics as a dependency
- no hidden host-only configuration
