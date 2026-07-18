#!/usr/bin/env bash
# Install desktop-local releases (SPEC §11 Phases 1–2)
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PROFILE="${ROOT}/values/desktop-local"

CTX="$(kubectl config current-context)"
if [[ "$CTX" != "docker-desktop" ]]; then
  echo "Refusing to install desktop-local against context '$CTX' (expected docker-desktop)." >&2
  exit 1
fi

echo "==> Creating namespaces"
kubectl create namespace langfuse --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace agent-observability --dry-run=client -o yaml | kubectl apply -f -

echo "==> Reminder: create Secrets before/alongside installs"
echo "    - langfuse/langfuse-secrets"
echo "    - agent-observability/otel-gateway-secrets"
echo "    - agent-observability/grafana-admin"
echo "    See .env.example and scripts/create-secrets.sh"

echo "==> Installing Langfuse"
helm upgrade --install langfuse langfuse/langfuse \
  --namespace langfuse \
  -f "${PROFILE}/langfuse.yaml" \
  --wait --timeout 15m || {
    echo "Langfuse install failed or timed out. Check PVC binding and chart field names." >&2
    exit 1
  }

echo "==> Installing Loki"
helm upgrade --install loki grafana/loki \
  --namespace agent-observability \
  -f "${PROFILE}/loki.yaml" \
  --wait --timeout 10m

echo "==> Installing Grafana"
helm upgrade --install grafana grafana/grafana \
  --namespace agent-observability \
  -f "${PROFILE}/grafana.yaml" \
  --wait --timeout 10m

echo "==> Installing OTel gateway"
helm upgrade --install otel-gateway open-telemetry/opentelemetry-collector \
  --namespace agent-observability \
  -f "${PROFILE}/otel-gateway.yaml" \
  --wait --timeout 10m

echo "==> Installing codex-telemetry-extension (disabled workloads by default)"
helm upgrade --install codex-telemetry-extension "${ROOT}/charts/codex-telemetry-extension" \
  --namespace agent-observability \
  -f "${PROFILE}/codex-telemetry-extension.yaml" \
  --wait --timeout 5m

echo "==> Applying NetworkPolicies"
kubectl apply -f "${ROOT}/network-policies/" -n agent-observability || true

echo "==> Releases"
helm list -A
echo "Next: ./scripts/expose-otel-gateway.sh && ./scripts/port-forward-uis.sh"
