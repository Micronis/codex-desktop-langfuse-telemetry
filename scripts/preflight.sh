#!/usr/bin/env bash
# Phase 0 — Preflight (SPEC §11)
set -euo pipefail

echo "==> Checking required tools"
for cmd in kubectl helm; do
  command -v "$cmd" >/dev/null || { echo "missing: $cmd" >&2; exit 1; }
done

echo "==> Kubernetes context (expect docker-desktop for desktop-local)"
CTX="$(kubectl config current-context)"
echo "    current-context: $CTX"
if [[ "$CTX" != "docker-desktop" ]]; then
  echo "WARN: context is not docker-desktop. Abort or switch before installing desktop-local." >&2
fi

echo "==> Cluster reachability"
kubectl cluster-info >/dev/null
kubectl get nodes

echo "==> Default StorageClass"
kubectl get storageclass || true

echo "==> Resource snapshot (best-effort)"
kubectl top nodes 2>/dev/null || echo "    metrics-server not available (ok for preflight)"

echo "==> Profile reminder"
echo "    Select desktop-local OR shared-cluster. Do not expose local values publicly."
echo "OK: preflight complete"
