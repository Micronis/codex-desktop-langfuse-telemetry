#!/usr/bin/env bash
# Preflight: prove 127.0.0.1:4317 / :4318 listen before configuring Codex.
set -euo pipefail

for port in 4317 4318; do
  if (echo >/dev/tcp/127.0.0.1/"$port") >/dev/null 2>&1; then
    echo "OK: 127.0.0.1:${port} reachable"
  else
    echo "FAIL: 127.0.0.1:${port} not reachable — start expose-otel-gateway.sh first" >&2
    exit 1
  fi
done

echo "Reminder: confirm the port is NOT reachable from another LAN device."
