CREATE EXTENSION IF NOT EXISTS vector;

CREATE TABLE IF NOT EXISTS leads (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    platform VARCHAR(50) NOT NULL,
    source_url TEXT,
    title TEXT NOT NULL,
    description TEXT NOT NULL,
    requirements TEXT,
    skills TEXT[] NOT NULL DEFAULT '{}',
    budget DECIMAL(10, 2),
    embedding vector(1536),
    status VARCHAR(20) NOT NULL DEFAULT 'new',
    raw_payload JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT leads_status_check CHECK (
        status IN ('new', 'analyzed', 'matched', 'ignored')
    )
);

CREATE TABLE IF NOT EXISTS contracts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    lead_id UUID NOT NULL REFERENCES leads(id) ON DELETE CASCADE,
    provider_profile TEXT,
    sourcing_query TEXT NOT NULL,
    expected_cost DECIMAL(10, 2),
    margin DECIMAL(10, 2),
    status VARCHAR(20) NOT NULL DEFAULT 'pending',
    audit_result JSONB NOT NULL DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    CONSTRAINT contracts_status_check CHECK (
        status IN ('pending', 'active', 'delivered', 'failed')
    )
);

CREATE TABLE IF NOT EXISTS payout_requests (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    contract_id UUID NOT NULL REFERENCES contracts(id) ON DELETE CASCADE,
    amount_cents INTEGER NOT NULL CHECK (amount_cents > 0),
    stripe_account_id TEXT NOT NULL,
    description TEXT,
    status VARCHAR(20) NOT NULL DEFAULT 'requires_approval',
    transfer_id TEXT,
    created_at TIMESTAMP WITH TIME ZONE NOT NULL DEFAULT NOW(),
    approved_at TIMESTAMP WITH TIME ZONE,
    CONSTRAINT payout_requests_status_check CHECK (
        status IN ('requires_approval', 'approved', 'sent', 'failed')
    )
);

CREATE INDEX IF NOT EXISTS idx_leads_status ON leads(status);
CREATE INDEX IF NOT EXISTS idx_leads_platform ON leads(platform);
CREATE INDEX IF NOT EXISTS idx_contracts_status ON contracts(status);
CREATE INDEX IF NOT EXISTS idx_contracts_lead_id ON contracts(lead_id);
CREATE INDEX IF NOT EXISTS idx_payout_requests_status ON payout_requests(status);
