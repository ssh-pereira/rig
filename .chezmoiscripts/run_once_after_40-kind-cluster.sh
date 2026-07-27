#!/bin/bash
# Creates the local practice Kubernetes cluster.
#
# Opt-in, because it needs Docker running and takes ~90s:
#   RIG_CREATE_KIND_CLUSTER=1 chezmoi apply

set -euo pipefail

if [[ "${RIG_CREATE_KIND_CLUSTER:-0}" != "1" ]]; then
  echo "▶ kind cluster — skipped (set RIG_CREATE_KIND_CLUSTER=1 to create)"
  exit 0
fi

echo "▶ local kind cluster"

command -v kind >/dev/null 2>&1 || { echo "  kind not installed yet, skipping"; exit 0; }

if ! docker info >/dev/null 2>&1; then
  echo "  ⚠ Docker isn't running. Start OrbStack, then re-run."
  exit 0
fi

if kind get clusters 2>/dev/null | grep -qx local; then
  echo "  cluster 'local' already exists"
else
  kind create cluster --config "$HOME/.config/kind/local-cluster.yaml"
fi

# nginx ingress, so an Ingress actually resolves from the browser on :80/:443
if ! kubectl get ns ingress-nginx >/dev/null 2>&1; then
  echo "  installing nginx ingress…"
  kubectl apply -f https://kind.sigs.k8s.io/examples/ingress/deploy-ingress-nginx.yaml
  kubectl wait --namespace ingress-nginx \
    --for=condition=ready pod \
    --selector=app.kubernetes.io/component=controller \
    --timeout=180s
fi

echo "  done — 3 nodes, ingress on :80/:443"
