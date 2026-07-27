# Kubernetes

## Safety first, every time

```bash
kubectl config current-context
```

Your prompt shows the context and namespace, and **production contexts render red**. A local `kind` cluster and a production cluster are otherwise indistinguishable.

| Command | Does |
|---|---|
| `kx` | fuzzy-switch cluster |
| `kx -` | switch back to the previous cluster |
| `kn` | fuzzy-switch namespace |

## Your local cluster

3 nodes (1 control-plane, 2 workers) in Docker via OrbStack, with nginx ingress on :80/:443.

```bash
kind get clusters
kind delete cluster -n local
kind create cluster --config ~/.config/kind/local-cluster.yaml
kind load docker-image myimg:tag -n local     # inject a local image, no registry
```

`kind load docker-image` is the non-obvious one: normally a cluster pulls from a registry. This pushes an image you just built straight into the nodes, so the loop is build → load → apply.

## Debugging order — work outside-in

Most people jump to logs. The answer is usually earlier.

1. **Events** — `kubectl get events --sort-by=.lastTimestamp -n <ns> | tail -40`
2. **Pod state** — `kubectl get pods -o wide` (RESTARTS, NODE, exact status string)
3. **Describe** — `kubectl describe pod <p>` — read the Events block at the bottom and `Last State` / `Exit Code`
4. **Logs** — `kubectl logs <p> --previous` ← the `--previous` is what actually crashed
5. **Resources** — `kubectl top pods` vs requests/limits
6. **Networking** — `kubectl get endpoints <svc>` ← **empty endpoints is the #1 cause of "the service is down"**
7. **Config** — does the ConfigMap/Secret key actually exist?

## Symptom → cause

| Status | Means |
|---|---|
| `Pending` | unschedulable — no CPU/memory, taint mismatch, unbound PVC |
| `ImagePullBackOff` | wrong tag, wrong registry, missing imagePullSecret |
| `CrashLoopBackOff` | read `--previous` logs. Exit 137 = OOMKilled. Exit 1 = app error |
| `CreateContainerConfigError` | missing ConfigMap/Secret **key** |
| `Running` but 5xx | readiness probe failing, or Service selector matches nothing |

## Things you probably don't know

- **`stern <pattern>`** — tail logs from *every* matching pod at once, colour-coded per pod. `kubectl logs` does one. With three replicas you don't know which served the failing request.

- **`kubectl get endpoints <svc>`** — if empty, the Service's selector doesn't match any pod's labels. Silent, and extremely common.

- **`kubectl diff -f manifest.yaml`** — shows what an apply *would* change. Run this before every apply.

- **`kubectl rollout undo deployment/x`** — instant rollback. Know this before you need it.

- **`kubectl rollout status deployment/x`** — blocks until the rollout finishes or fails. Use it in scripts instead of sleeping.

- **`kubectl explain pod.spec.containers.resources`** — the schema, from the cluster itself. Beats searching docs, and it's version-accurate.

- **`kubectl get po -o yaml`** vs **`-o jsonpath='{.items[*].spec.nodeName}'`** — jsonpath extracts one field across many objects without jq.

- **`kubectl debug`** — attach an ephemeral container to a running pod. The way into a distroless image with no shell:
  ```bash
  kubectl debug -it <pod> --image=busybox --target=<container>
  ```

- **`kubectl port-forward svc/x 8080:80`** — reach a cluster service on localhost. No ingress needed.

- **`kubectl auth can-i --list`** — what am I actually allowed to do here? Answers RBAC questions instantly.

- **`kubectl api-resources`** — every resource type in this cluster including CRDs, with short names.

- **`kubectl top nodes`** — actual usage vs capacity. Needs metrics-server.

- **`kubectl cordon` / `drain`** — stop scheduling to a node / evict everything off it. How you do maintenance.

- **`kubectl get all -A`** doesn't actually show *all* — it misses secrets, configmaps, ingresses, and CRDs. There's no single command; that surprises people.

## k9s — live here instead

`k9s` is the TUI. Keys inside it:

| Key | Does |
|---|---|
| `:pods`, `:svc`, `:deploy` | jump to a resource type |
| `/foo` | filter |
| `l` | logs · `Shift-L` previous logs |
| `d` | describe · `y` view YAML |
| `s` | shell into the container |
| `Ctrl-D` | delete |
| `:ctx` | switch cluster |
| `?` | help |

## Learn by breaking it

```bash
kubectl create deployment web --image=nginx --replicas=3
kubectl get pods -o wide                    # watch them spread across nodes
kubectl delete pod <one>                    # watch a replacement appear

kubectl set resources deployment web --limits=memory=8Mi
kubectl describe pod <p>                    # OOMKilled, exit 137

kubectl expose deployment web --port=80
kubectl get endpoints web                   # has endpoints
kubectl label pods -l app=web app=broken --overwrite
kubectl get endpoints web                   # EMPTY — selector no longer matches

kubectl delete deployment web svc/web
```

That last one is the most common real-world outage cause, and it's invisible unless you check `endpoints`.
