import json
from typing import Any

from openai import OpenAI

from arbitrage_lattice.config import Settings, get_settings
from arbitrage_lattice.models import AuditResult, StructuredLead


class AgentError(RuntimeError):
    """Raised when an agent cannot produce a valid structured response."""


class CognitiveAgents:
    """OpenAI-backed Hunter, Broker, and Auditor agents."""

    def __init__(self, settings: Settings | None = None, client: OpenAI | None = None):
        self.settings = settings or get_settings()
        if client is not None:
            self.client = client
            return
        if not self.settings.has_openai or self.settings.openai_api_key is None:
            raise AgentError("OPENAI_API_KEY is required")
        self.client = OpenAI(
            api_key=self.settings.openai_api_key.get_secret_value(),
        )

    def run_hunter(self, raw_lead_text: str) -> StructuredLead:
        system_prompt = (
            "You are the Hunter Agent for a compliant lead triage workflow. "
            "Extract legitimate project demand from user-provided or authorized "
            "lead text. Return strict JSON with project_title, requirements, "
            "budget, and skills. Use null when budget is unknown."
        )
        content = self._chat_json(system_prompt, raw_lead_text)
        return StructuredLead.model_validate(content)

    def run_broker(self, structured_lead: StructuredLead) -> str:
        system_prompt = (
            "You are the Broker Agent. Given a structured project lead, generate "
            "one concise sourcing search query for finding a qualified provider. "
            "Return only the search query, without formatting or preamble."
        )
        response = self.client.chat.completions.create(
            model=self.settings.openai_model,
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": structured_lead.model_dump_json()},
            ],
        )
        content = response.choices[0].message.content
        if not content:
            raise AgentError("Broker Agent returned an empty response")
        return content.strip()

    def run_auditor(self, submitted_deliverable: str, original_brief: str) -> AuditResult:
        system_prompt = (
            "You are the Auditor Agent. Compare a completed deliverable against "
            "the original brief. Identify missing features, quality issues, and "
            "formatting errors. Return strict JSON with status, confidence, "
            "issues, and reason. status must be pass or fail."
        )
        content = self._chat_json(
            system_prompt,
            f"BRIEF:\n{original_brief}\n\nDELIVERABLE:\n{submitted_deliverable}",
        )
        return AuditResult.model_validate(content)

    def _chat_json(self, system_prompt: str, user_content: str) -> dict[str, Any]:
        response = self.client.chat.completions.create(
            model=self.settings.openai_model,
            response_format={"type": "json_object"},
            messages=[
                {"role": "system", "content": system_prompt},
                {"role": "user", "content": user_content},
            ],
        )
        content = response.choices[0].message.content
        if not content:
            raise AgentError("Agent returned an empty response")
        try:
            parsed = json.loads(content)
        except json.JSONDecodeError as exc:
            raise AgentError("Agent returned invalid JSON") from exc
        if not isinstance(parsed, dict):
            raise AgentError("Agent JSON response must be an object")
        return parsed
