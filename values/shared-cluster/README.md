# Shared-cluster profile

This overlay is a **separate** deployment configuration from `desktop-local`.
Do not reuse desktop-local networking or storage assumptions and then add a public endpoint.

## Required changes vs desktop-local

| Concern | Shared-cluster expectation |
| --- | --- |
| Desktop-to-collector | Authenticated OTLP ingress / VPN / private network — never anonymous public |
| Storage | Cluster-approved StorageClass, backup, capacity monitoring |
| Langfuse stores | Managed services or production-grade stateful deployment |
| Secrets | External secret manager + workload identity |
| Access | SSO / authenticated ingress + RBAC |
| Operations | GitOps, upgrade policy, incident ownership |

## Files

- `otel-gateway.yaml` — private authenticated listener placeholders
- `langfuse.yaml` — external/managed store placeholders
- `loki.yaml` / `grafana.yaml` — production-oriented stubs
- `codex-telemetry-extension.yaml` — same chart, cluster secret wiring

Fill in org-specific StorageClass, ingress class, and identity settings before any install.
