# app

This folder contains the sample application used as the container workload for the ECS platform.

The app is intentionally small, because the repo is mainly about the infrastructure and delivery pattern.

---

## What is inside

- `app.py` — FastAPI application
- `requirements.txt` — Python dependencies
- `Dockerfile` — image build definition

---

## What the app does

The sample app currently exposes:
- `/health` — health response with host and environment
- `/api/cidr?cidr=...` — CIDR calculator endpoint
- `/` — small HTML front end

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

This app gives the Terraform and ECS layers a real workload target:
- image source
- container port
- health endpoint
- sample environment behavior

That keeps the project grounded in something deployable instead of being infrastructure for infrastructure’s sake.
