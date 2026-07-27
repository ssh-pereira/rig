---
name: incident-response
description: Structured triage for a live production incident — stabilise first, diagnose second. Use when something is down, erroring, or degraded in production and Hugo needs to work through it fast.
---

# Incident response

Something is broken in production. The goal for the first ten minutes is **stop the bleeding**, not understand the bug. Root cause comes after users are served.

## 0. Establish the facts (2 min)

Answer these before touching anything:

- **What is the user-visible symptom?** Not "the API is erroring" — "checkout returns 500 for all users".
- **When did it start?** Correlate with the last deploy: `gh pr list --state merged --limit 10`.
- **What is the blast radius?** All users or some? One region? One endpoint?
- **Is it still happening,** or did it self-resolve?

Confirm your context before running anything: `kubectl config current-context`

## 1. Stabilise

The fastest safe fix wins. In order of preference:

1. **Roll back.** If it started right after a deploy, the deploy is the cause until proven otherwise.
   ```bash
   kubectl rollout undo deployment/<name> -n <ns>
   kubectl rollout status deployment/<name> -n <ns>
   ```
2. **Feature flag off.** If the project has a flag covering the broken path, this is faster and lower-risk than a rollback.
3. **Scale out.** If it's load or resource pressure and not a code bug.
4. **Only then** consider a forward fix. Writing new code during an incident is a last resort.

Do not debug a broken production while it stays broken. Restore, then investigate the artifacts.

## 2. Gather evidence

Do this *while* stabilising, and capture it to a file — logs roll off and you'll need them for the write-up.

```bash
kubectl get events --sort-by=.lastTimestamp -n <ns> | tail -50
kubectl get pods -o wide -n <ns>
stern <pattern> -n <ns> --since 30m > /tmp/incident-logs.txt
kubectl top pods -n <ns>
```

Whatever error tracker and analytics the project uses, pull two things: the **error signature and its first-seen timestamp**, and **when the user-facing metric moved**. First-seen in an error tracker is usually the most precise start time available.

## 3. Diagnose

Hand off to the **k8s-debugger** subagent for cluster-level symptoms. For application errors, work from the stack trace to the code, then to the change that introduced it:

```bash
git log --oneline --since="2 days ago" -- <path>
```

The question to answer is *what changed*. A system that was fine yesterday and broken today changed — code, config, data volume, or an upstream dependency.

## 4. Communicate

Post early and update on a rhythm, even with "still investigating". Silence reads as nothing happening.

Structure each update:
- **Impact** — who is affected and how.
- **Status** — investigating / identified / mitigating / monitoring / resolved.
- **Next update** — a specific time.

## 5. After

Once resolved and monitored for a stable period:

- Write the timeline while it's fresh: detection → diagnosis → mitigation → resolution, with timestamps.
- Identify what made it slow to *detect* or slow to *fix*. That's usually more valuable than the bug itself.
- File follow-ups in whatever tracker the project uses, linked to the incident.
- Blameless. The output is a system change, not a person resolving to be more careful.

## Don't

- Don't apply Terraform during an incident unless the infrastructure *is* the incident.
- Don't make several changes at once — you won't know which one worked.
- Don't skip the write-up because it resolved itself. Self-resolving incidents recur.
