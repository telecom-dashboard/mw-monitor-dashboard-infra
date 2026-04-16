# app

This folder contains a small legacy test application kept for the ECS-oriented Terraform path.

It is not the primary business application and it is not the current MVP deploy source of truth. The live application code now lives in `telecom-dashboard/mw-dashboard-app`.

---

## What is inside

- `app.py` - FastAPI application
- `requirements.txt` - Python dependencies
- `Dockerfile` - image build definition

---

## What the app does

The test app currently exposes:
- `/health` - health response with host and environment
- `/api/cidr?cidr=...` - CIDR calculator endpoint
- `/` - small HTML front end

That makes it more useful than a meaningless hello-world container while still staying simple.

---

## Run locally with Python

From the `app/` folder:

```bash
pip install -r requirements.txt
uvicorn app:app --host 0.0.0.0 --port 3000
```

Then open:

```text
http://localhost:3000
```

---

## Run with Docker

From the `app/` folder:

```bash
docker build -t cidr-buddy .
docker run --rm -p 3000:3000 cidr-buddy
```

---

## Why this exists in the repo

This app gives the Terraform ECS layers a lightweight workload target:
- image source
- container port
- health endpoint
- sample environment behavior

That keeps the future ECS path testable without mixing the main business app code into this infra repo.
