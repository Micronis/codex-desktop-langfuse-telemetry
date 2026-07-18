"""Evaluator skeleton: named scores only; blocks quality scores without complete evidence."""

from __future__ import annotations

import os
from typing import Any

from fastapi import FastAPI
from pydantic import BaseModel, Field

app = FastAPI(title="codex-evaluator", version="0.1.0")

LLM_JUDGE_ENABLED = os.getenv("LLM_JUDGE_ENABLED", "false").lower() == "true"
LLM_JUDGE_ENDPOINT = os.getenv("LLM_JUDGE_ENDPOINT", "")


class TraceEvidence(BaseModel):
    trace_id: str
    has_approved_prompt: bool = False
    has_complete_output: bool = False
    input_tokens: int | None = None
    output_tokens: int | None = None
    duration_ms: float | None = None
    tool_retries: int = 0
    subagent_count: int = 0
    task_completed_evidence: bool | None = None
    redaction_violation: bool = False


class ScoreResult(BaseModel):
    name: str
    value: Any
    producer: str
    rubric_or_policy_version: str
    evidence_source: str


class EvaluateRequest(BaseModel):
    evidence: TraceEvidence
    existing_human_scores: list[str] = Field(default_factory=list)


@app.get("/healthz")
def healthz() -> dict[str, Any]:
    return {
        "status": "ok",
        "llm_judge_enabled": LLM_JUDGE_ENABLED,
        "llm_judge_endpoint_configured": bool(LLM_JUDGE_ENDPOINT),
    }


@app.post("/evaluate", response_model=list[ScoreResult])
def evaluate(req: EvaluateRequest) -> list[ScoreResult]:
    scores: list[ScoreResult] = []
    e = req.evidence

    if "task_completed" not in req.existing_human_scores and e.task_completed_evidence is not None:
        scores.append(
            ScoreResult(
                name="task_completed",
                value=bool(e.task_completed_evidence),
                producer="deterministic",
                rubric_or_policy_version="v1",
                evidence_source="acceptance_or_test_result",
            )
        )

    if e.input_tokens is not None and e.duration_ms is not None:
        # Placeholder efficiency: inverse of retries/subagents; calibrate later.
        efficiency = max(0.0, min(1.0, 1.0 / (1 + e.tool_retries + max(0, e.subagent_count - 1))))
        scores.append(
            ScoreResult(
                name="execution_efficiency",
                value=efficiency,
                producer="deterministic",
                rubric_or_policy_version="v1",
                evidence_source="tokens_duration_retries_subagents",
            )
        )

    scores.append(
        ScoreResult(
            name="safety_or_privacy_violation",
            value=bool(e.redaction_violation),
            producer="deterministic",
            rubric_or_policy_version="v1",
            evidence_source="redaction_scan",
        )
    )

    # Automated response_quality / prompt_clarity require complete evidence.
    if LLM_JUDGE_ENABLED and LLM_JUDGE_ENDPOINT:
        if e.has_approved_prompt and e.has_complete_output and "response_quality" not in req.existing_human_scores:
            # Kill-switch aware stub — do not call external model until calibrated.
            pass
        if e.has_approved_prompt and "prompt_clarity" not in req.existing_human_scores:
            pass

    return scores
