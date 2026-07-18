#!/usr/bin/env bash
# Add and update official Helm repositories (SPEC §11 Phase 1)
set -euo pipefail

helm repo add open-telemetry https://open-telemetry.github.io/opentelemetry-helm-charts 2>/dev/null || true
helm repo add langfuse https://langfuse.github.io/langfuse-k8s 2>/dev/null || true
helm repo add grafana https://grafana.github.io/helm-charts 2>/dev/null || true
helm repo update

echo "==> Available chart versions (record into versions.yaml)"
helm search repo open-telemetry/opentelemetry-collector --versions | head -5
helm search repo langfuse/langfuse --versions | head -5
helm search repo grafana/loki --versions | head -5
helm search repo grafana/grafana --versions | head -5
