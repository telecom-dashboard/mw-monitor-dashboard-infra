# Capacity and Operations

## 1. How ECS handles growth

ECS handles application growth by adding more healthy tasks behind the ALB.

```text
More users
  -> higher request rate
  -> ALB spreads load
  -> ECS Service Auto Scaling increases task count
  -> more app capacity becomes available
```

### Conditions required for good ECS scaling

- application is stateless
- sessions are externalized or otherwise safe
- tasks start quickly
- health checks are accurate
- CPU/memory/task count are tuned
- database is not the actual bottleneck

### Common ECS bottlenecks

- slow container startup
- bad health check path
- too few subnets / IPs
- wrong task CPU/memory sizing
- app opens too many DB connections
- one noisy endpoint dominates all traffic

## 2. How RDS handles growth

RDS handles growth through a mix of:

- **vertical scaling** — bigger instance class
- **storage scaling** — more storage / storage autoscaling
- **read scaling** — read replicas for read-heavy workloads
- **availability scaling** — Multi-AZ for failover posture
- **connection scaling** — RDS Proxy reduces connection storms

```text
More users
  -> more API requests
  -> more DB connections
  -> more reads/writes
  -> DB may saturate before ECS does
```

### Important truth

Many user growth often breaks the **database first**, not the app servers first.

Do not assume adding ECS tasks alone solves scale.

## 3. Recommended scaling posture for this project

### Stage 1 — immediately after ECS cutover
- fixed task count
- manual DB sizing
- no fancy scaling during first week
- monitor actual behavior first

### Stage 2 — after stability proven
- ECS target tracking on CPU and/or request count
- review slow queries
- add RDS Proxy if connection churn is visible
- add read replica only if real read pressure exists

### Stage 3 — after product traction
- tune autoscaling thresholds
- consider Multi-AZ
- consider separate frontend delivery path
- consider caching layer only when metrics justify it

## 4. Minimum recommended alarms

### ALB
- HTTPCode_ELB_5XX_Count
- HTTPCode_Target_5XX_Count
- TargetResponseTime
- UnHealthyHostCount

### ECS
- CPUUtilization
- MemoryUtilization
- running task count
- deployment failures
- task restart loops

### RDS
- CPUUtilization
- DatabaseConnections
- FreeStorageSpace
- FreeableMemory
- ReadLatency
- WriteLatency
- ReplicaLag if replicas exist

### App-level
- failed login / auth anomalies
- request error rate
- p95 / p99 latency
- import/export failure count
- background job failures if any

## 5. Backup and restore posture

### Minimum posture

- automated RDS backups
- manual snapshot before major migration
- app config exported and versioned
- Terraform state protected
- restore drill documented

### Hard truth

A backup you never restored is a bedtime story, not a recovery plan.

## 6. High availability posture

### MVP
- low availability
- single host blast radius
- recovery depends on operator skill

### RDS single-AZ
- managed database operations
- still limited HA

### RDS Multi-AZ
- stronger failover posture
- higher cost
- usually worth it once the system matters

### ECS behind ALB
- stronger application availability
- safer deploys
- easier instance/task replacement

## 7. Capacity planning cheatsheet

| Metric pattern | Likely problem | Likely response |
|---|---|---|
| ECS CPU high, DB normal | app tier pressure | scale ECS tasks |
| ECS normal, DB connections high | connection storm | use pooling / RDS Proxy / app pool tuning |
| DB CPU high, ECS low | query or DB bottleneck | optimize queries or resize DB |
| ALB latency high, both ECS and DB moderate | network or downstream dependency | inspect logs, tracing, dependencies |
| storage dropping fast | retention / uploads / DB growth | scale storage, clean up, lifecycle rules |

## 8. Operational guardrails

- one deployment method per environment
- one source of truth for secrets
- one clear health endpoint
- one rollback path per change
- no manual changes on live hosts without documentation
- no schema change without rollback thought
- no "we'll remember what we changed" nonsense

## 9. Suggested next improvements after migration

- add a synthetic canary against the main dashboard path
- create a one-command smoke test script
- create a one-page incident cheat sheet
- separate deploy approval from deploy execution for prod
- document exact ownership of DNS, ALB, ECS, RDS, and secrets
