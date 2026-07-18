# Grafana folder: Codex Desktop

Do **not** invent panel field paths. Per SPEC §8:

1. Capture a sanitized `codex.sse_event` sample from Loki after Phase 2–3.
2. Map observed attributes into panels.
3. Export JSON dashboards into this directory and wire via ConfigMap / Grafana provisioning.

## Required panels (after field validation)

| Panel | Signal |
| --- | --- |
| Active runs | trace/log start and completion |
| Completed turns | `response.completed` token counts |
| Token trend | 5-minute aggregates |
| Subagent activity | parent relationship when supplied; else unknown |
| Errors and retries | `codex.api_request` |
| Tool activity | `codex.tool_decision` / `codex.tool_result` |
| Content-capture coverage | normalizer audit fields |
| Score coverage | Langfuse scores |
| Quality trend | calibrated scores only |
