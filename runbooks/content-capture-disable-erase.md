# Runbook: Disable and erase content-capture project

One-command-oriented procedure for the `codex-desktop-content` Langfuse project and related PVCs (SPEC §6.2 / §9).

## Disable (immediate)

```bash
# 1. Desktop: set log_user_prompt = false and restart ChatGPT desktop
# 2. Revert collector logs pipeline to Loki-only
helm upgrade otel-gateway open-telemetry/opentelemetry-collector \
  --namespace agent-observability \
  -f values/desktop-local/otel-gateway.yaml

# 3. Disable normalizer / evaluator
helm upgrade codex-telemetry-extension ./charts/codex-telemetry-extension \
  --namespace agent-observability \
  -f values/desktop-local/codex-telemetry-extension.yaml
```

## Erase content project data

```bash
# Rotate/delete content-project API keys in Langfuse UI first.
# Then, if the content project used dedicated PVC-backed storage shared with metadata,
# prefer Langfuse project delete + selective retention purge over deleting shared PVCs.

# Nuclear option (desktop-local only — destroys ALL Langfuse state):
# helm uninstall langfuse -n langfuse
# kubectl -n langfuse delete pvc --all
```

Prefer project-level delete in the Langfuse UI when available so metadata-only `codex-desktop` data is retained.

## Verify

- Grafana / Loki sample query shows no new user-prompt fields.
- Normalizer Deployment replicas = 0 or release values have `normalizer.enabled: false`.
- Content project credentials removed from Secrets.
