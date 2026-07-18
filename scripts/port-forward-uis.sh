#!/usr/bin/env bash
# Loopback port-forwards for Langfuse and Grafana UIs (SPEC §5.1)
set -euo pipefail

echo "Starting UI port-forwards on 127.0.0.1 only..."
echo "  Langfuse: http://127.0.0.1:3000"
echo "  Grafana:  http://127.0.0.1:3001"

kubectl -n langfuse port-forward --address 127.0.0.1 svc/langfuse-web 3000:3000 &
PF1=$!
kubectl -n agent-observability port-forward --address 127.0.0.1 svc/grafana 3001:80 &
PF2=$!

cleanup() {
  kill "$PF1" "$PF2" 2>/dev/null || true
}
trap cleanup EXIT INT TERM

wait
