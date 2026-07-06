# crypto

## Cursor Cloud specific instructions

### Repository shape (important)

The base branch `main` currently contains only `README.md`. The actual code lives on
separate feature branches, and each branch is a **distinct product with its own
toolchain**. Check out the relevant branch (or use a `git worktree`) before working:

| Product | Branch | Stack | External services |
|---|---|---|---|
| Epistemic Ledger Foundry (on-chain attestation registry) | `cursor/build-foundry-project-4a13` | Solidity / Foundry | None (fully local) |
| Arbitrage Lattice (compliance-first lead triage CLI) | `cursor/arbitrage-lattice-72de` | Python 3.12 | Supabase + OpenAI (+ Stripe) |

Toolchains are preinstalled in the VM snapshot: Foundry (`forge`/`cast`/`anvil`/`chisel`,
on `PATH` via `~/.foundry/bin` in `~/.bashrc`), Python 3.12 with `python3.12-venv`, and
Node 22. `psql` and `docker` are **not** installed.

### Epistemic Ledger Foundry (`cursor/build-foundry-project-4a13`)

Fully runnable with no secrets or external services. Standard commands are in that
branch's `README.md`. The only non-obvious gotcha:

- Run `git submodule update --init --recursive` before `forge build` — dependencies
  (`forge-std`, `openzeppelin-contracts`) are git submodules and the build fails without
  them.
- Lint/build: `forge build`. Test: `forge test`. Demo/run: `forge script script/Demo.s.sol`
  (prints the attestation registry flow; `Status: 2` == `Verified`).

### Arbitrage Lattice (`cursor/arbitrage-lattice-72de`)

Python CLI installed with a venv + editable install (see that branch's `README.md`).
Non-obvious caveats:

- There is **no local-only code path**. Every subcommand instantiates a Supabase and/or
  OpenAI client at startup, so even `list-leads` requires `SUPABASE_URL` + `SUPABASE_KEY`,
  and the `ingest-*` commands additionally require `OPENAI_API_KEY`. `prepare-payout` and
  approved transfers require `STRIPE_SECRET_KEY`. Set these (e.g. via `.env`, see
  `.env.example`) before attempting any real action.
- The schema in `db/schema.sql` needs the Postgres `vector` (pgvector) extension; apply it
  to your Supabase/Postgres database before running.
- After changing dependencies, reinstall inside the venv (`pip install -e .`).
