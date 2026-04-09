# bootstrap backend

This Terraform root creates the persistent S3 bucket used as the remote backend for the environment Terraform roots.

---

## What it creates

- S3 bucket for Terraform state
- bucket versioning
- server-side encryption
- public access block settings

This is a control-plane resource. It should usually stay alive even when dev or prod infrastructure is destroyed.

---

## Why it matters

Remote state is the spine of the repo.

Without it:
- dev and prod state drift becomes easier
- CI cannot reliably use shared state
- migration between local and CI becomes messier
- recovery gets more painful than it needs to be

---

## Input

This root expects a bucket name to be supplied.

Example:
```bash
terraform plan -var="bucket_name=heinzawhtoo-tf-state-123456789012-apse1"
terraform apply -var="bucket_name=heinzawhtoo-tf-state-123456789012-apse1"
```

You can also use a local tfvars file if you prefer.

---

## Commands

Run from this folder:

```bash
cd terraform/bootstrap/backend
terraform init
terraform fmt -check
terraform validate
terraform plan -var="bucket_name=YOUR_TF_STATE_BUCKET"
```

Apply:
```bash
terraform apply -var="bucket_name=YOUR_TF_STATE_BUCKET"
```

---

## Recommended naming

A bucket naming pattern like this keeps migrations easier to reason about:

```text
<name>-tf-state-<aws-account-id>-<region-shortcode>
```

Example:
```text
heinzawhtoo-tf-state-091336586598-apse1
```

---

## Operational guidance

Keep this bucket persistent.

Destroying it casually is a bad habit because it blows away the control plane history for both environments.

Destroy it only when you are intentionally tearing down the whole project and you fully understand the consequences.
