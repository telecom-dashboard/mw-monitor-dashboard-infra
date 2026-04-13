# bootstrap oidc

This Terraform root creates the GitHub Actions OIDC provider and the bootstrap IAM role trusted by that provider.

---

## What it creates

- GitHub Actions OIDC provider for `token.actions.githubusercontent.com`
- IAM role trusted by that provider

This is the first AWS-side building block needed for GitHub Actions OIDC.

---

## Why this root exists

The repo uses GitHub Actions OIDC so CI does **not** need long-lived AWS access keys stored in GitHub.

That gives you:
- cleaner CI auth
- less secret sprawl
- better account migration hygiene
- fewer terrible future decisions

---

## Commands

Run from this folder:

```bash
cd terraform/bootstrap/oidc
terraform init
terraform fmt -check
terraform validate
terraform plan
```

Apply:
```bash
terraform apply
```

---

## Migration note

This root often uses **local state** during bootstrap.

If you move to a new AWS account and Terraform is still trying to refresh an old-account OIDC provider, the most likely cause is stale local state in this folder.

In that case:
1. verify the active AWS account with `aws sts get-caller-identity`
2. back up or remove stale local state files
3. run `terraform init -reconfigure`
4. plan again

---

## If the OIDC provider already exists

Do not blindly recreate it.

Import it instead, for example:

```bash
terraform import aws_iam_openid_connect_provider.github arn:aws:iam::<ACCOUNT_ID>:oidc-provider/token.actions.githubusercontent.com
```

If the IAM role already exists, import that too before planning.

---

## What to edit here

Edit this folder when you need to change:
- GitHub org trust
- GitHub repo trust
- allowed branch
- bootstrap role name

Do not use this folder for day-to-day environment tuning.
