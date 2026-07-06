from pathlib import Path

import httpx

from arbitrage_lattice.agents import CognitiveAgents
from arbitrage_lattice.models import ContractCreate, LeadCreate, LeadRecord, LeadStatus
from arbitrage_lattice.storage import SupabaseStorage


class DiscoveryError(RuntimeError):
    """Raised when lead discovery cannot safely ingest source material."""


class DiscoveryService:
    """Coordinates authorized lead ingestion, structuring, and contract drafting."""

    def __init__(
        self,
        agents: CognitiveAgents | None = None,
        storage: SupabaseStorage | None = None,
    ):
        self.agents = agents or CognitiveAgents()
        self.storage = storage or SupabaseStorage()

    def ingest_text(
        self,
        *,
        platform: str,
        text: str,
        source_url: str | None = None,
    ) -> LeadRecord:
        structured = self.agents.run_hunter(text)
        lead = self.storage.create_lead(
            LeadCreate(
                platform=platform,
                source_url=source_url,
                title=structured.project_title,
                description=text,
                requirements=structured.requirements,
                skills=structured.skills,
                budget=structured.budget,
                status=LeadStatus.ANALYZED,
                raw_payload={"source": "text"},
            )
        )
        sourcing_query = self.agents.run_broker(structured)
        self.storage.create_contract(
            ContractCreate(
                lead_id=lead.id,
                sourcing_query=sourcing_query,
            )
        )
        self.storage.update_lead_status(lead.id, LeadStatus.MATCHED)
        return lead

    def ingest_file(self, *, platform: str, path: Path) -> LeadRecord:
        if not path.exists() or not path.is_file():
            raise DiscoveryError(f"Lead file does not exist: {path}")
        text = path.read_text(encoding="utf-8")
        return self.ingest_text(platform=platform, text=text)

    async def ingest_authorized_url(self, *, platform: str, url: str) -> LeadRecord:
        async with httpx.AsyncClient(
            timeout=30.0,
            follow_redirects=True,
            headers={"User-Agent": "arbitrage-lattice/0.1 compliance-ingestor"},
        ) as client:
            response = await client.get(url)
            response.raise_for_status()
        return self.ingest_text(platform=platform, text=response.text, source_url=url)
