#!/usr/bin/env bash
# Create Kubernetes Secrets from environment variables (.env — gitignored)
set -euo pipefail

if [[ -f .env ]]; then
  # shellcheck disable=SC1091
  set -a; source .env; set +a
fi

: "${NEXTAUTH_SECRET:?set NEXTAUTH_SECRET}"
: "${LANGFUSE_POSTGRES_PASSWORD:?set LANGFUSE_POSTGRES_PASSWORD}"
: "${LANGFUSE_CLICKHOUSE_PASSWORD:?set LANGFUSE_CLICKHOUSE_PASSWORD}"
: "${LANGFUSE_REDIS_PASSWORD:?set LANGFUSE_REDIS_PASSWORD}"
: "${GRAFANA_ADMIN_PASSWORD:?set GRAFANA_ADMIN_PASSWORD}"

kubectl create namespace langfuse --dry-run=client -o yaml | kubectl apply -f -
kubectl create namespace agent-observability --dry-run=client -o yaml | kubectl apply -f -

kubectl -n langfuse create secret generic langfuse-secrets \
  --from-literal=nextauth-secret="${NEXTAUTH_SECRET}" \
  --from-literal=salt="${NEXTAUTH_SECRET}" \
  --from-literal=postgres-password="${LANGFUSE_POSTGRES_PASSWORD}" \
  --from-literal=clickhouse-password="${LANGFUSE_CLICKHOUSE_PASSWORD}" \
  --from-literal=redis-password="${LANGFUSE_REDIS_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

GRAFANA_ADMIN_USER="${GRAFANA_ADMIN_USER:-admin}"
kubectl -n agent-observability create secret generic grafana-admin \
  --from-literal=admin-user="${GRAFANA_ADMIN_USER}" \
  --from-literal=admin-password="${GRAFANA_ADMIN_PASSWORD}" \
  --dry-run=client -o yaml | kubectl apply -f -

if [[ -n "${LANGFUSE_PUBLIC_KEY:-}" && -n "${LANGFUSE_SECRET_KEY:-}" ]]; then
  AUTH="${LANGFUSE_OTLP_AUTHORIZATION:-}"
  if [[ -z "$AUTH" ]]; then
    AUTH="Basic $(printf '%s:%s' "$LANGFUSE_PUBLIC_KEY" "$LANGFUSE_SECRET_KEY" | base64 -w0 2>/dev/null || printf '%s:%s' "$LANGFUSE_PUBLIC_KEY" "$LANGFUSE_SECRET_KEY" | base64)"
  fi
  ENDPOINT="${LANGFUSE_OTLP_ENDPOINT:-http://langfuse-web.langfuse.svc.cluster.local:3000/api/public/otel}"
  kubectl -n agent-observability create secret generic otel-gateway-secrets \
    --from-literal=langfuse-otlp-endpoint="${ENDPOINT}" \
    --from-literal=langfuse-otlp-authorization="${AUTH}" \
    --dry-run=client -o yaml | kubectl apply -f -
  echo "otel-gateway-secrets created (Langfuse project keys present)"
else
  echo "WARN: LANGFUSE_PUBLIC_KEY/SECRET_KEY unset — create otel-gateway-secrets after project keys exist"
fi

echo "Secrets applied (no values written to git)."
