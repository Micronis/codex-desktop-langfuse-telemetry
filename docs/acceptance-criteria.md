# Acceptance criteria

Copied from SPEC §12. The deployment is complete only when all conditions are true:

- [ ] `helm list -A` shows healthy releases for `langfuse`, `otel-gateway`, `loki`, `grafana`, and the disabled-by-default `codex-telemetry-extension` release.
- [ ] All stateful components have bound PVCs and survive a Docker Desktop restart.
- [ ] `127.0.0.1:4317` is reachable from Windows, while the port is not reachable from another LAN device.
- [ ] A desktop Codex task produces an OTel trace visible in Langfuse within one minute of completion.
- [ ] The same task produces a Loki completion event that includes the documented token-count payload when present.
- [ ] Grafana can show the task's model, duration, and observed token fields without scraping or parsing ChatGPT UI data.
- [ ] A two-subagent run produces distinct worker activity records or explicitly documented limitations if Codex does not export the parent-child relationship.
- [ ] `log_user_prompt` remains `false` and no prompt content appears in a sample query.
- [ ] Langfuse, Grafana, and OTLP endpoints are inaccessible from the LAN and require localhost access paths only.
- [ ] In metadata-only mode, the normalizer/evaluator receives no prompt or output body.
- [ ] In content-capture mode, a non-sensitive canary proves that only approved prompt/output fields are retained and that unknown fields/tool-output bodies are redacted or dropped.
- [ ] A trace without a verified complete output cannot receive `response_quality` or `prompt_clarity` from an automated evaluator.
- [ ] A retried source event does not create duplicate Langfuse observations or scores.
- [ ] Each score records its type, producer, rubric/policy version, and evidence source.
