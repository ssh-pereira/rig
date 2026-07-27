# Terraform

## The workflow, in order

Each step catches something the next one can't.

```
0. Read the repo's CLAUDE.md / AGENTS.md   conventions differ per project
1. Name the target environment             ambiguity here is the expensive mistake
2. terraform fmt -recursive && validate
3. terraform plan -out=tfplan              then enumerate the destroys
4. infracost breakdown --path .
5. trivy config .
6. Review (the terraform-reviewer agent)
7. terraform apply tfplan                  the SAVED plan, never a bare apply
8. terraform plan again                    must come back clean
```

## The two commands that matter most

**Enumerate destroys** — the thing that's easy to miss in a 400-line plan:
```bash
terraform show -json tfplan | jq -r '.resource_changes[]
  | select(.change.actions[] | . == "delete") | .address'
```
Anything stateful in that list — database, disk, bucket, secret, static IP, DNS zone — stops the process. A `-/+` replace on a database is **data loss**, not a change.

**Cost before applying:**
```bash
infracost breakdown --path .
```

## Why `apply tfplan` and not `apply`

A bare `terraform apply` re-plans at apply time. If anything changed in between — someone else's apply, a data source resolving differently — you apply something you never reviewed. `apply tfplan` applies exactly what you read.

## Things you probably don't know

- **`terraform console`** — a REPL against your state and variables. Test an expression before putting it in a resource:
  ```
  > cidrsubnet("10.0.0.0/16", 8, 2)
  > [for s in var.subnets : s.name]
  ```

- **`terraform state list`** / **`state show <addr>`** — inspect state without a plan.

- **`terraform state mv`** — rename a resource in state without destroying it. What you use after refactoring a module so Terraform doesn't destroy-and-recreate.

- **`terraform state rm`** — forget a resource without deleting the real thing. The escape hatch when state and reality diverge.

- **`terraform import`** — adopt an existing resource created by hand.

- **`moved` blocks** (in code, not CLI) — declarative renames that travel with the repo, so teammates don't each run `state mv`:
  ```hcl
  moved {
    from = aws_instance.old
    to   = aws_instance.new
  }
  ```

- **`terraform plan -refresh-only`** — show drift only: what changed in the real world versus state, with no proposed changes. The honest answer to "did someone edit this in the console?"

- **`terraform apply -target=...`** — apply one resource. Legitimate for breaking a dependency cycle, a smell everywhere else.

- **`terraform graph | dot -Tsvg > graph.svg`** — visualise the dependency graph.

- **`terraform output -json | jq`** — machine-readable outputs for scripts.

- **`terraform providers lock -platform=darwin_arm64 -platform=linux_amd64`** — lock provider hashes for multiple platforms, so CI on Linux and your Mac agree.

- **`TF_LOG=DEBUG`** — provider-level logging when a plan makes no sense.

- **`terraform taint`** is deprecated — use `terraform apply -replace=<addr>`.

- **`terraform-docs markdown table . > README.md`** — generate module docs from variables and outputs. Keeps docs honest for free.

## Aliases here

| Alias | Full |
|---|---|
| `tf` | `terraform` |
| `tfi` / `tfp` / `tfa` | init / plan / apply |
| `tfd` | destroy |
| `tff` | `fmt -recursive` |
| `tfv` | `validate` |
| `tg` | `terragrunt` |

Your prompt shows the current **workspace**, red if it matches prod.

## Rollback

Before applying to production, answer: *how do I undo this in under five minutes?* If the answer is "restore from backup", the change needs more thought first.
