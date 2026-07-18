#!/usr/bin/env bash
# Expose OTel gateway to Windows loopback only (SPEC §5.2)
# Preferred: Docker Desktop LoadBalancer / local-service route.
# Fallback: supervised kubectl port-forward bound to 127.0.0.1.
set -euo pipefail

NS=agent-observability
SVC=otel-gateway-opentelemetry-collector
# Chart may name the Service differently — discover if needed.
if ! kubectl -n "$NS" get svc "$SVC" >/dev/null 2>&1; then
  SVC="$(kubectl -n "$NS" get svc -l app.kubernetes.io/name=opentelemetry-collector -o jsonpath='{.items[0].metadata.name}' 2>/dev/null || true)"
fi
if [[ -z "${SVC:-}" ]]; then
  echo "Could not find otel-gateway Service in $NS" >&2
  exit 1
fi

echo "==> Service: $NS/$SVC"
kubectl -n "$NS" get svc "$SVC" -o wide

echo "==> Fallback: port-forward to 127.0.0.1:4317 and :4318"
echo "    Treat this process as part of the stack lifecycle."
echo "    NEVER use --address 0.0.0.0"
exec kubectl -n "$NS" port-forward --address 127.0.0.1 "svc/${SVC}" 4317:4317 4318:4318
