from uuid import UUID

import httpx

from arbitrage_lattice.config import Settings, get_settings
from arbitrage_lattice.models import PayoutRequestCreate, PayoutRequestRecord
from arbitrage_lattice.storage import SupabaseStorage


class SettlementError(RuntimeError):
    """Raised when payout preparation or settlement fails."""


class SettlementService:
    """Prepares payout requests and handles explicitly approved transfers."""

    def __init__(
        self,
        settings: Settings | None = None,
        storage: SupabaseStorage | None = None,
    ):
        self.settings = settings or get_settings()
        self.storage = storage or SupabaseStorage()

    def prepare_payout_request(
        self,
        *,
        contract_id: UUID,
        amount_cents: int,
        stripe_account_id: str,
        description: str | None = None,
    ) -> PayoutRequestRecord:
        payout_request = PayoutRequestCreate(
            contract_id=contract_id,
            amount_cents=amount_cents,
            stripe_account_id=stripe_account_id,
            description=description,
        )
        return self.storage.create_payout_request(payout_request)

    async def send_approved_transfer(
        self,
        *,
        amount_cents: int,
        stripe_account_id: str,
        description: str | None = None,
        approval_confirmed: bool,
    ) -> str:
        if not approval_confirmed:
            raise SettlementError("Explicit payout approval is required")
        if not self.settings.has_stripe or self.settings.stripe_secret_key is None:
            raise SettlementError("STRIPE_SECRET_KEY is required")

        async with httpx.AsyncClient(timeout=30.0) as client:
            response = await client.post(
                "https://api.stripe.com/v1/transfers",
                auth=(self.settings.stripe_secret_key.get_secret_value(), ""),
                data={
                    "amount": str(amount_cents),
                    "currency": "usd",
                    "destination": stripe_account_id,
                    "description": description or "",
                },
            )
        response.raise_for_status()
        payload = response.json()
        transfer_id = payload.get("id")
        if not transfer_id:
            raise SettlementError("Stripe response did not include a transfer id")
        return transfer_id
