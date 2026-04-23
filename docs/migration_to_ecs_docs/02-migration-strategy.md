# Migration Strategy

## 1. Strategy summary

Use a **phased migration**, not a big-bang rewrite.

Recommended phases:

1. MVP hardening
2. ALB bridge stage
3. Database migration to RDS
4. ECS runtime migration
5. autoscaling, proxying, and operational hardening

## 2. Zero or minimum downtime principle

### Application tier

Near-zero downtime is achievable if:

- old and new runtimes run in parallel
- health checks are real
- traffic shifts only after validation
- rollback target remains alive during bake time

### Database tier

True zero downtime is much harder.

For your project, the right target is:

- full load into RDS
- continuous change replication
- short controlled cutover
- brief write freeze
- switch app connection string
- verify
- reopen writes

That is **minimum downtime**, not magic.

## 3. Recommended migration sequence

## Phase 0 — Harden the MVP first

Do this before any architecture migration.

### Deliverables

- EC2 AMI or documented host rebuild procedure
- EBS snapshot schedule
- PostgreSQL dump schedule
- restore test on non-prod host
- CloudWatch alarms
- health endpoint for backend
- smoke test script
- documented rollback script
- confirmed Parameter Store paths and ownership
- no secrets hard-coded on host

### Exit criteria

- you can rebuild the current MVP without panic
- you can restore the database from backup
- you can validate app health in under 5 minutes

---

## Phase 1 — Introduce ALB in front of the current EC2

### Goal

Keep the current app exactly as it is, but change the public entry point to ALB.

### Steps

1. Provision ALB and target group.
2. Register current EC2 as target.
3. Set health check path, for example `/api/health`.
4. Validate HTTP and HTTPS behavior.
5. Cut Route 53 to the ALB.
6. Keep EC2 deployment flow unchanged.

### Why this matters

This creates a stable front door for later ECS cutovers.

### Rollback

Point Route 53 back to the old EC2 public endpoint if needed.

### Exit criteria

- ALB forwards traffic successfully
- health checks are stable
- no change required to app code
- current users see no behavioral change

---

## Phase 2 — Move PostgreSQL from EC2 to RDS

### Goal

Remove the biggest operational risk first: host-local database.

### Recommended methods

#### Method A — AWS DMS or equivalent CDC-based migration
Best for:
- minimizing downtime
- keeping source live until final cutover

Flow:
1. create RDS PostgreSQL
2. baseline schema and extensions
3. full load data
4. enable ongoing replication / CDC
5. monitor lag
6. schedule cutover
7. briefly freeze writes
8. allow final sync
9. switch app DB endpoint
10. validate
11. reopen writes

#### Method B — PostgreSQL native logical replication
Best for:
- PostgreSQL-to-PostgreSQL teams comfortable with DB internals

#### Method C — pg_dump / pg_restore
Best for:
- small database
- acceptable maintenance window
- simplest tooling

### Recommended choice

If the dataset is still small and downtime tolerance is a few minutes, `pg_dump/pg_restore` may be enough.

If you want the cleanest "real-world" migration pattern and lower downtime, use **continuous replication**.

### RDS cutover SOP summary

```text
1. announce maintenance window
2. verify target RDS healthy
3. confirm replication lag near zero
4. enable app read-only mode or stop writers
5. perform final sync
6. switch backend DB endpoint / secrets
7. restart backend
8. run smoke tests
9. reopen writes
10. monitor errors, connections, latency
```

### Rollback

If cutover fails:
- stop new writes
- switch app back to source database
- restart backend on old DB endpoint
- investigate before retrying

### Exit criteria

- app is stable on RDS
- backup, monitoring, parameter group, and maintenance settings are reviewed
- EC2 local PostgreSQL is no longer the primary

---

## Phase 3 — Prepare ECS runtime in dev

### Goal

Make the application runtime portable before moving production traffic.

### Tasks

- build container image(s)
- push to ECR
- define ECS task definition
- define service and target group
- define health checks
- move runtime config to env vars / Parameter Store
- remove host-specific assumptions
- test file paths, startup, and logging
- test DB connection to RDS
- validate deploys in `terraform/envs/dev`

### Design rule

The app must be **stateless**:

- no required local persistent data
- no manual host edits
- no reliance on EC2-only directory layout
- no secrets fetched from ad-hoc shell hacks only available on one host

### Exit criteria

- ECS dev deploy succeeds
- health checks pass
- logs are visible in CloudWatch
- app behaves like MVP from a user perspective

---

## Phase 4 — Production ECS cutover

### Goal

Move production traffic from EC2 runtime to ECS runtime.

### Preferred traffic pattern

```text
ALB
  -> Target Group A = current EC2
  -> Target Group B = ECS service
```

Then:

1. deploy ECS service without traffic or with test-only routing
2. validate health
3. shift a small portion of traffic or swap target groups
4. monitor
5. complete cutover
6. keep EC2 alive for rollback until confidence window expires

### Practical cutover pattern

#### Safer pattern
- keep EC2 as blue
- ECS as green
- validate green
- swap traffic
- hold blue intact for rollback

#### Fast pattern
- update listener to route all traffic to ECS after validation
- retain EC2 but remove from listener only after stable bake time

### Rollback

Re-point ALB listener back to EC2 target group.

### Exit criteria

- ECS serves production traffic
- rollback path proven
- EC2 no longer needed for steady state
- deploy flow no longer depends on SSM Run Command to a single host

---

## Phase 5 — Post-cutover hardening

Do these after the first stable week, not during the first cutover.

- enable ECS service autoscaling
- evaluate RDS Proxy
- tune task CPU/memory
- tune DB instance size and storage
- consider Multi-AZ
- add canary or synthetic tests
- reduce ALB deregistration delay if needed
- rotate legacy credentials
- decommission old host safely

## 4. Downtime decision matrix

| Situation | Recommended method | Expected impact |
|---|---|---|
| very small DB, maintenance window acceptable | pg_dump / restore | simple but longer downtime |
| moderate DB, want short cutover | continuous replication | best balance |
| app migration only, DB already on RDS | ALB blue/green | near-zero app downtime |
| database + app both moving same day | avoid if possible | highest risk |

## 5. What not to do

Do **not** do these on the same day unless you absolutely must:

- change domain structure
- change TLS termination style
- change database engine version significantly
- change app routing style
- change frontend delivery architecture
- change deploy tooling and runtime platform at the same time

That is how outages become "learning experiences" with emotional damage.

## 6. Recommended timeline

### Sprint 1
- harden MVP
- backups
- health checks
- smoke tests
- restore drill

### Sprint 2
- ALB bridge
- Route 53 cutover
- no app behavior change

### Sprint 3
- RDS build
- migration rehearsal
- DB cutover rehearsal

### Sprint 4
- prod DB cutover to RDS

### Sprint 5
- ECS dev validation
- production cutover rehearsal

### Sprint 6
- ECS production cutover
- keep EC2 warm as rollback target

## 7. Acceptance checklist

A migration phase is only done when:

- documented
- rehearsed
- monitored
- rollback tested
- owned by named operator(s)
- measurable by clear pass/fail checks
