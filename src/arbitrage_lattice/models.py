from decimal import Decimal
from enum import StrEnum
from uuid import UUID

from pydantic import BaseModel, Field, HttpUrl


class LeadStatus(StrEnum):
    NEW = "new"
    ANALYZED = "analyzed"
    MATCHED = "matched"
    IGNORED = "ignored"


class ContractStatus(StrEnum):
    PENDING = "pending"
    ACTIVE = "active"
    DELIVERED = "delivered"
    FAILED = "failed"


class PayoutStatus(StrEnum):
    REQUIRES_APPROVAL = "requires_approval"
    APPROVED = "approved"
    SENT = "sent"
    FAILED = "failed"


class StructuredLead(BaseModel):
    project_title: str = Field(min_length=1)
    requirements: str = Field(min_length=1)
    budget: Decimal | None = None
    skills: list[str] = Field(default_factory=list)


class LeadCreate(BaseModel):
    platform: str = Field(min_length=1, max_length=50)
    source_url: HttpUrl | None = None
    title: str = Field(min_length=1)
    description: str = Field(min_length=1)
    requirements: str | None = None
    skills: list[str] = Field(default_factory=list)
    budget: Decimal | None = None
    status: LeadStatus = LeadStatus.NEW
    raw_payload: dict = Field(default_factory=dict)


class LeadRecord(LeadCreate):
    id: UUID


class ContractCreate(BaseModel):
    lead_id: UUID
    sourcing_query: str = Field(min_length=1)
    provider_profile: str | None = None
    expected_cost: Decimal | None = None
    margin: Decimal | None = None
    status: ContractStatus = ContractStatus.PENDING
    audit_result: dict = Field(default_factory=dict)


class ContractRecord(ContractCreate):
    id: UUID


class AuditResult(BaseModel):
    status: str = Field(pattern="^(pass|fail)$")
    confidence: float = Field(ge=0.0, le=1.0)
    issues: list[str] = Field(default_factory=list)
    reason: str


class PayoutRequestCreate(BaseModel):
    contract_id: UUID
    amount_cents: int = Field(gt=0)
    stripe_account_id: str = Field(min_length=1)
    description: str | None = None
    status: PayoutStatus = PayoutStatus.REQUIRES_APPROVAL


class PayoutRequestRecord(PayoutRequestCreate):
    id: UUID
