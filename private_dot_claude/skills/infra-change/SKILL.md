---
name: infra-change
description: The safe workflow for making a Terraform or Kubernetes change — plan, cost, scan, review, apply, verify. Use whenever infrastructure files change or Hugo asks to deploy, apply, or modify infra.
---

# Making an infrastructure change

Cloud-agnostic. Never skip to apply — each step below catches something the next one can't.

## 0. Read the repo's conventions first

Find and read the project's `CLAUDE.md` / `AGENTS.md`, including any under `infrastructure/`. Naming rules, required labels or tags, module layout, and environment names are **per-project**. Follow what's written there; don't import conventions from another repo.

Identify the environment scheme from the directory layout — commonly `dev`/`stg`/`prd` or `dev`/`staging`/`production`. Treat anything matching `prd`/`prod` as production.

## 1. Name the target

State out loud: **which environment, which resources.** If that's not unambiguous from the request, ask.

Promotion order is always lowest → highest. A change that hasn't run in staging doesn't go to production.

## 2. Write the change

Follow the repo's conventions. General principles that hold everywhere:
- Shared logic goes in a module, not copy-pasted between environments.
- Don't hardcode values the repo already defines as a local or variable.
- Keep the diff scoped to the stated task.

Then: `terraform fmt -recursive && terraform validate`

## 3. Plan

```bash
terraform plan -no-color -out=tfplan
```

Read it. Count the destroys and replaces explicitly:

```bash
terraform show -json tfplan | jq -r '.resource_changes[] | select(.change.actions[] | . == "delete") | .address'
```

Anything stateful in that list — databases, disks, buckets, secrets, static IPs, DNS zones — stops the process for a human decision. A `-/+` replace on a database is data loss, not a change.

## 4. Cost

```bash
infracost breakdown --path .
```

Report the monthly delta. A change that silently adds hundreds a month is a finding even if technically correct.

## 5. Scan

```bash
trivy config .
```

Plus `gitleaks detect --no-banner` if anything near secrets was touched.

## 6. Review

Hand the plan to the **terraform-reviewer** subagent. It checks blast radius, IAM widening, public exposure, deletion protection, and conventions. Don't skip this because the diff looks small — small diffs cause most incidents.

## 7. Apply

Only after 1–6 are clean and Hugo has seen the plan.

```bash
terraform apply tfplan
```

Apply the **saved plan file**, never a bare `terraform apply` — that re-plans and can pick up changes you never reviewed.

## 8. Verify

- Run `terraform plan` again. It must come back clean. A dirty plan right after apply means drift or a misconfigured resource.
- For Kubernetes: `kubectl rollout status deployment/<name> -n <ns>`, then check events and pod health.
- Check the actual service works, not just that the resources exist.

## Kubernetes specifics

Confirm context before anything:

```bash
kubectl config current-context
```

Diff before applying:

```bash
kubectl diff -f <manifest>
```

Apply, watch the rollout, and know the rollback before you need it:

```bash
kubectl rollout undo deployment/<name> -n <ns>
```

## Rollback plan

Before applying to production, answer: *how do I undo this in under five minutes?* If the answer is "restore from backup", the change needs more thought first.
