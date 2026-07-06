# Autonomous Arbitrage Lattice

This repository contains a compliance-first implementation scaffold for an
autonomous lead triage and fulfillment-routing workflow.

The system is split into four bounded layers:

1. **Discovery** - ingest lead text from approved feeds, exports, or URLs that
   you are authorized to access.
2. **Cognitive routing** - use AI to structure raw leads and generate sourcing
   search phrases.
3. **Storage** - persist leads, contracts, margins, and audit results in
   PostgreSQL/Supabase.
4. **Settlement review** - prepare payout requests after quality review while
   keeping final disbursement behind an explicit approval step.

This project intentionally does not include stealth browser bypasses, account
evasion, or automatic third-party marketplace actions. Connectors should use
official APIs, exported data, partner feeds, or pages where automated access is
allowed.

## Project layout

```text
.
├── .env.example
├── db/schema.sql
├── pyproject.toml
├── src/arbitrage_lattice/
│   ├── agents.py
│   ├── config.py
│   ├── discovery.py
│   ├── main.py
│   ├── models.py
│   ├── settlement.py
│   └── storage.py
└── systemd/arbitrage-lattice.service
```

## Setup

```bash
python -m venv .venv
source .venv/bin/activate
pip install -e .
cp .env.example .env
```

Populate `.env` with your Supabase and OpenAI credentials, then apply the
database schema in `db/schema.sql` to your Supabase SQL editor or PostgreSQL
database.

## Running

Process approved lead text directly:

```bash
arbitrage-lattice ingest-text \
  --platform reddit \
  --text "Need a landing page built for a local HVAC company. Budget $300."
```

Ingest from a file:

```bash
arbitrage-lattice ingest-file --platform partner-feed --path leads.txt
```

List recent leads:

```bash
arbitrage-lattice list-leads
```

Prepare a payout request for manual approval:

```bash
arbitrage-lattice prepare-payout \
  --contract-id <contract-id> \
  --amount-cents 4500 \
  --stripe-account acct_123 \
  --description "Fulfillment payment for approved deliverable"
```

## Deployment

Use `systemd/arbitrage-lattice.service` as a starting point for a durable Linux
service. Update the paths and user to match your server before installation.
