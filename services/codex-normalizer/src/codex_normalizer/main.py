"""Minimal OTLP/HTTP logs receiver stub implementing the SPEC §7.2 contract skeleton.

Does not invent missing prompt/output fields or parent-child relationships.
Semantic mapping stays off until content-capture is enabled and schema is verified.
"""

from __future__ import annotations

import hashlib
import json
import os
import re
from pathlib import Path
from typing import Any

from fastapi import FastAPI, Request, Response

app = FastAPI(title="codex-normalizer", version=os.getenv("NORMALIZER_VERSION", "0.1.0"))

CONTENT_CAPTURE = os.getenv("CONTENT_CAPTURE", "false").lower() == "true"
NORMALIZER_VERSION = os.getenv("NORMALIZER_VERSION", "0.1.0")
REDACTION_POLICY_VERSION = os.getenv("REDACTION_POLICY_VERSION", "v1")
SCHEMA_VERSION = os.getenv("SCHEMA_VERSION", "v1")

# Idempotency cache (in-memory; replace with durable store for production use)
_SEEN_KEYS: set[str] = set()

SECRET_PATTERNS = [
    re.compile(p, re.I)
    for p in [
        r"api[_-]?key\s*[:=]\s*\S+",
        r"authorization\s*[:=]\s*\S+",
        r"bearer\s+[A-Za-z0-9._\-]+",
        r"password\s*[:=]\s*\S+",
        r"sk-[A-Za-z0-9]{20,}",
    ]
]

ALWAYS_ALLOW = {
    "event_type",
    "event_id",
    "time",
    "conversation_id",
    "agent_id",
    "thread_id",
    "parent_conversation_id",
    "model",
    "reasoning_effort",
    "sse_type",
    "input_tokens",
    "output_tokens",
    "total_tokens",
    "duration_ms",
    "status",
}

CONTENT_ALLOW = {"user_prompt"}  # assistant_output only after canary approval


def _stable_key(event: dict[str, Any]) -> str:
    raw = f"{event.get('event_id','')}|{event.get('event_type','')}|{event.get('time','')}"
    return hashlib.sha256(raw.encode()).hexdigest()


def _redact_string(value: str) -> str:
    out = value
    for pat in SECRET_PATTERNS:
        out = pat.sub("<redacted>", out)
    return out


def _allowlist(event: dict[str, Any]) -> dict[str, Any]:
    allowed = set(ALWAYS_ALLOW)
    if CONTENT_CAPTURE:
        allowed |= CONTENT_ALLOW
    cleaned: dict[str, Any] = {}
    for k, v in event.items():
        if k not in allowed:
            continue
        if isinstance(v, str):
            cleaned[k] = _redact_string(v)
        else:
            cleaned[k] = v
    return cleaned


def _map_to_langfuse_record(event: dict[str, Any]) -> dict[str, Any]:
    """Build a Langfuse-oriented observation payload without fabricating content."""
    has_prompt = bool(event.get("user_prompt"))
    has_full_output = bool(event.get("assistant_output"))
    record: dict[str, Any] = {
        "type": "generation" if (CONTENT_CAPTURE and has_prompt and has_full_output) else "observation",
        "conversation_id": event.get("conversation_id"),
        "model": event.get("model"),
        "metadata": {
            "normalizer_version": NORMALIZER_VERSION,
            "redaction_policy_version": REDACTION_POLICY_VERSION,
            "schema_version": SCHEMA_VERSION,
            "content_capture": CONTENT_CAPTURE,
            "source_event_type": event.get("event_type"),
            "source_event_id": event.get("event_id"),
            "output_capture": (
                "complete"
                if has_full_output
                else ("partial_or_absent" if has_prompt else "unavailable")
            ),
        },
    }
    if record["type"] == "generation":
        record["input"] = event.get("user_prompt")
        record["output"] = event.get("assistant_output")
    elif has_prompt and CONTENT_CAPTURE:
        record["input"] = event.get("user_prompt")
        record["metadata"]["output_capture"] = "unavailable"
    # Never invent parent-child links; only pass through if present.
    if event.get("parent_conversation_id"):
        record["metadata"]["parent_conversation_id"] = event["parent_conversation_id"]
    else:
        record["metadata"]["parent_relationship"] = "unknown"
    return record


@app.get("/healthz")
def healthz() -> dict[str, str]:
    return {"status": "ok", "normalizer_version": NORMALIZER_VERSION}


@app.post("/v1/logs")
async def otlp_logs(request: Request) -> Response:
    """Accept OTLP/HTTP logs. Full OTLP protobuf/JSON decoding can replace this stub."""
    body = await request.body()
    try:
        payload = json.loads(body) if body else {}
    except json.JSONDecodeError:
        return Response(status_code=400, content="invalid json")

    # Stub: expect a simplified envelope with resourceLogs → ... → body attributes,
    # or a test-friendly top-level {"events": [...]}.
    events = payload.get("events") or _extract_events_stub(payload)
    accepted = 0
    for raw in events:
        event = _allowlist(raw if isinstance(raw, dict) else {})
        if not event.get("event_id"):
            continue
        key = _stable_key(event)
        if key in _SEEN_KEYS:
            continue
        _SEEN_KEYS.add(key)
        _ = _map_to_langfuse_record(event)
        # TODO: write via Langfuse SDK using LANGFUSE_* env credentials
        accepted += 1
    return Response(status_code=200, content=json.dumps({"accepted": accepted}))


def _extract_events_stub(payload: dict[str, Any]) -> list[dict[str, Any]]:
    """Best-effort pull of attribute maps from OTLP JSON; refine after canary samples."""
    out: list[dict[str, Any]] = []
    for rl in payload.get("resourceLogs", []) or []:
        for sl in rl.get("scopeLogs", []) or []:
            for lr in sl.get("logRecords", []) or []:
                attrs = {a.get("key"): _attr_value(a.get("value")) for a in lr.get("attributes", [])}
                if attrs:
                    out.append(attrs)
    return out


def _attr_value(value: Any) -> Any:
    if not isinstance(value, dict):
        return value
    for k in ("stringValue", "intValue", "doubleValue", "boolValue"):
        if k in value:
            return value[k]
    return value


def load_policy(path: str | Path) -> dict[str, Any]:
    import yaml

    return yaml.safe_load(Path(path).read_text(encoding="utf-8"))
