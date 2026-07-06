import argparse
import asyncio
import time
from pathlib import Path
from uuid import UUID

from arbitrage_lattice.discovery import DiscoveryService
from arbitrage_lattice.settlement import SettlementService
from arbitrage_lattice.storage import SupabaseStorage


def main() -> None:
    parser = argparse.ArgumentParser(
        prog="arbitrage-lattice",
        description="Compliance-first lead triage and fulfillment routing",
    )
    subcommands = parser.add_subparsers(dest="command", required=True)

    ingest_text = subcommands.add_parser("ingest-text", help="Ingest approved lead text")
    ingest_text.add_argument("--platform", required=True)
    ingest_text.add_argument("--text", required=True)
    ingest_text.add_argument("--source-url")

    ingest_file = subcommands.add_parser("ingest-file", help="Ingest approved lead file")
    ingest_file.add_argument("--platform", required=True)
    ingest_file.add_argument("--path", type=Path, required=True)

    ingest_url = subcommands.add_parser("ingest-url", help="Ingest an authorized URL")
    ingest_url.add_argument("--platform", required=True)
    ingest_url.add_argument("--url", required=True)

    list_leads = subcommands.add_parser("list-leads", help="List recent leads")
    list_leads.add_argument("--limit", type=int, default=25)

    serve = subcommands.add_parser("serve", help="Run a durable worker heartbeat")
    serve.add_argument("--interval-seconds", type=int, default=300)

    prepare_payout = subcommands.add_parser(
        "prepare-payout",
        help="Create a payout request that requires separate approval",
    )
    prepare_payout.add_argument("--contract-id", type=UUID, required=True)
    prepare_payout.add_argument("--amount-cents", type=int, required=True)
    prepare_payout.add_argument("--stripe-account", required=True)
    prepare_payout.add_argument("--description")

    args = parser.parse_args()

    if args.command == "ingest-text":
        service = DiscoveryService()
        lead = service.ingest_text(
            platform=args.platform,
            text=args.text,
            source_url=args.source_url,
        )
        print(f"Created lead {lead.id}")
        return

    if args.command == "ingest-file":
        service = DiscoveryService()
        lead = service.ingest_file(platform=args.platform, path=args.path)
        print(f"Created lead {lead.id}")
        return

    if args.command == "ingest-url":
        service = DiscoveryService()
        lead = asyncio.run(
            service.ingest_authorized_url(platform=args.platform, url=args.url)
        )
        print(f"Created lead {lead.id}")
        return

    if args.command == "list-leads":
        storage = SupabaseStorage()
        for lead in storage.list_leads(limit=args.limit):
            budget = f" budget={lead.budget}" if lead.budget is not None else ""
            print(f"{lead.id} [{lead.status}] {lead.platform}: {lead.title}{budget}")
        return

    if args.command == "serve":
        storage = SupabaseStorage()
        while True:
            leads = storage.list_leads(limit=5)
            print(f"worker heartbeat: {len(leads)} recent leads visible", flush=True)
            time.sleep(args.interval_seconds)

    if args.command == "prepare-payout":
        service = SettlementService()
        payout = service.prepare_payout_request(
            contract_id=args.contract_id,
            amount_cents=args.amount_cents,
            stripe_account_id=args.stripe_account,
            description=args.description,
        )
        print(f"Created payout request {payout.id} with status {payout.status}")
        return

    parser.error(f"Unhandled command: {args.command}")


if __name__ == "__main__":
    main()
