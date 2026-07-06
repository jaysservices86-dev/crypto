from typing import Any
from uuid import UUID

from supabase import Client, create_client

from arbitrage_lattice.config import Settings, get_settings
from arbitrage_lattice.models import (
    ContractCreate,
    ContractRecord,
    LeadCreate,
    LeadRecord,
    LeadStatus,
    PayoutRequestCreate,
    PayoutRequestRecord,
)


class StorageError(RuntimeError):
    """Raised when persistent storage is unavailable or rejects a request."""


class SupabaseStorage:
    """Small repository wrapper around Supabase tables used by the lattice."""

    def __init__(self, settings: Settings | None = None, client: Client | None = None):
        self.settings = settings or get_settings()
        if client is not None:
            self.client = client
            return
        if not self.settings.has_supabase:
            raise StorageError("SUPABASE_URL and SUPABASE_KEY are required")
        key = self.settings.supabase_key
        if key is None:
            raise StorageError("SUPABASE_KEY is required")
        self.client = create_client(self.settings.supabase_url, key.get_secret_value())

    def create_lead(self, lead: LeadCreate) -> LeadRecord:
        payload = lead.model_dump(mode="json", exclude_none=True)
        result = self.client.table("leads").insert(payload).execute()
        return LeadRecord.model_validate(_single_row(result.data, "lead"))

    def update_lead_status(self, lead_id: UUID, status: LeadStatus) -> None:
        self.client.table("leads").update({"status": status.value}).eq(
            "id", str(lead_id)
        ).execute()

    def create_contract(self, contract: ContractCreate) -> ContractRecord:
        payload = contract.model_dump(mode="json", exclude_none=True)
        result = self.client.table("contracts").insert(payload).execute()
        return ContractRecord.model_validate(_single_row(result.data, "contract"))

    def create_payout_request(
        self, payout_request: PayoutRequestCreate
    ) -> PayoutRequestRecord:
        payload = payout_request.model_dump(mode="json", exclude_none=True)
        result = self.client.table("payout_requests").insert(payload).execute()
        return PayoutRequestRecord.model_validate(
            _single_row(result.data, "payout request")
        )

    def list_leads(self, limit: int = 25) -> list[LeadRecord]:
        result = (
            self.client.table("leads")
            .select("*")
            .order("created_at", desc=True)
            .limit(limit)
            .execute()
        )
        return [LeadRecord.model_validate(row) for row in result.data or []]


def _single_row(rows: list[dict[str, Any]] | None, label: str) -> dict[str, Any]:
    if not rows:
        raise StorageError(f"Supabase did not return the created {label}")
    return rows[0]
