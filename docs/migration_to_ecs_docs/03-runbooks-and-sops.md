# Runbooks and SOPs

## 1. Pre-flight checklist

Use this before any migration event.

### Change management

- [ ] change window approved
- [ ] stakeholders informed
- [ ] rollback owner assigned
- [ ] technical lead assigned
- [ ] monitoring dashboard ready
- [ ] communication channel open
- [ ] latest docs available locally

### Access

- [ ] AWS console access works
- [ ] Terraform access works
- [ ] CI/CD access works
- [ ] SSM access works
- [ ] Route 53 access works
- [ ] RDS access works
- [ ] CloudWatch access works
- [ ] GitHub secrets / vars confirmed

### Validation

- [ ] current production baseline captured
- [ ] request latency baseline captured
- [ ] DB size captured
- [ ] active connection count captured
- [ ] free disk/storage captured
- [ ] recent backups verified
- [ ] restore test result recorded
- [ ] smoke test commands prepared

---

## 2. Migration day roles

### Suggested roles

- **Driver** — executes the runbook
- **Navigator** — reads the SOP, confirms each step, watches for mistakes
- **Observer** — watches dashboards, logs, and user symptoms
- **Approver** — decides continue / rollback at decision points

For a small team, one person may wear multiple hats.
Still, separate "doing" from "checking" whenever possible.

---

## 3. Database migration SOP

## Scenario
EC2-local PostgreSQL -> Amazon RDS PostgreSQL

### Before the window

- [ ] target RDS created
- [ ] parameter group reviewed
- [ ] security groups reviewed
- [ ] backup retention configured
- [ ] application secret path prepared
- [ ] schema compatibility reviewed
- [ ] replication or dump rehearsal completed
- [ ] cutover checklist printed or saved locally

### Cutover steps

```text
1. Announce cutover start.
2. Confirm current app health is green.
3. Confirm source DB backup exists.
4. Confirm target RDS health is green.
5. Confirm replication lag is acceptable or full load is complete.
6. Enable maintenance mode or freeze writes.
7. Perform final sync.
8. Update app DB endpoint/credentials.
9. Restart backend or redeploy app.
10. Run smoke tests.
11. Validate error rate, login, dashboard load, read/write behavior.
12. Reopen traffic / writes.
13. Monitor closely for 30 to 60 minutes.
```

### Smoke tests after DB cutover

- [ ] homepage loads
- [ ] login/auth works if applicable
- [ ] dashboard loads
- [ ] API health endpoint returns success
- [ ] read query works
- [ ] write query works
- [ ] file import/export still works
- [ ] no spike in 5xx
- [ ] DB connections stable
- [ ] app logs clean enough to continue

### Rollback criteria

Rollback immediately if:

- app cannot start against target DB
- critical data missing
- write operations fail
- error rate spikes materially
- latency becomes unacceptable
- operator confidence drops below "this is under control"

### Rollback steps

```text
1. Freeze writes again.
2. Point app back to original DB endpoint.
3. Restart or redeploy backend.
4. Verify smoke tests.
5. Reopen writes.
6. Preserve target logs and evidence.
7. Document failure cause before retrying.
```

---

## 4. ECS production cutover SOP

## Scenario
ALB target group cutover from EC2 to ECS

### Preconditions

- [ ] RDS is already primary
- [ ] ECS service healthy in target environment
- [ ] task definition pinned and known
- [ ] image tag pinned and known
- [ ] ALB target group health checks green
- [ ] old EC2 target still healthy
- [ ] dashboards open
- [ ] rollback listener action prepared

### Cutover steps

```text
1. Confirm EC2 target group healthy.
2. Confirm ECS target group healthy.
3. Shift traffic to ECS using listener rule change or blue/green action.
4. Observe 1 min, 5 min, 15 min checkpoints.
5. Run smoke tests at each checkpoint.
6. If stable, complete traffic shift.
7. Keep EC2 target alive for bake period.
8. Remove EC2 from live path only after confidence window.
```

### Smoke tests after ECS cutover

- [ ] frontend loads
- [ ] API health endpoint green
- [ ] dashboard data appears
- [ ] authentication/session behavior correct
- [ ] no unexpected CORS issues
- [ ] uploads/downloads work
- [ ] logs flowing to CloudWatch
- [ ] task restart count stable
- [ ] ALB 5xx not elevated
- [ ] DB connection saturation not increasing dangerously

### Rollback steps

```text
1. Shift traffic back to EC2 target group.
2. Confirm user-facing service recovery.
3. Keep ECS running for investigation.
4. Preserve task logs and events.
5. Open incident review item before another attempt.
```

---

## 5. Fast troubleshooting matrix

| Symptom | Likely area | First check |
|---|---|---|
| ALB 502/503 | target health / app startup | ECS target health, container logs |
| app starts but DB errors | credentials / SG / RDS | DB endpoint, secret values, SG rules |
| high latency after cutover | DB saturation or cold tasks | RDS CPU/connections, ECS CPU/mem |
| intermittent failures | connection churn | consider RDS Proxy, connection pool settings |
| one target healthy, one unhealthy | config drift | env vars, health path, image tag |
| deploy succeeded but app broken | bad config / migration mismatch | startup logs, migration logs, health endpoint |

## 6. Post-event checklist

- [ ] confirm stable for agreed observation window
- [ ] capture final metrics
- [ ] record exact cutover time
- [ ] record any deviations from SOP
- [ ] record follow-up items
- [ ] schedule old-resource cleanup only after confidence window
