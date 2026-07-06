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

Note: a separate local-only FastAPI "Epistemic Ledger" project (Python 3.14, SQLite,
`core/`, `api/`, `oracles/`) is described in some handoffs but has **not** been pushed to
this repo, so it cannot be built or run from the cloud VM.

### Toolchain / environment

The base VM ships Python 3.12 (`/usr/bin/python3.12`) and Node 22. The startup update
script additionally installs `python3.12-venv` (apt) and Foundry (via `foundryup`).
`psql` and `docker` are **not** installed.

- Foundry binaries land in `~/.foundry/bin` and are **not** on `PATH` in non-interactive
  shells. Export it first: `export PATH="$HOME/.foundry/bin:$PATH"` (or run `~/.foundry/bin/forge`).

### Epistemic Ledger Foundry (`cursor/build-foundry-project-4a13`)

Fully runnable with no secrets or external services. Standard commands are in that
branch's `README.md`. The only non-obvious gotcha:

- Run `git submodule update --init --recursive` before `forge build` — dependencies
  (`forge-std`, `openzeppelin-contracts`) are git submodules and the build fails without
  them. The startup update script does not do this (it runs from `main`, where the
  submodules do not exist).
- Lint/build: `forge build`. Test: `forge test`. Demo/run: `forge script script/Demo.s.sol`
  (prints the attestation registry flow; `Status: 2` == `Verified`). A `block.timestamp`
  lint warning during build is expected and documented in `docs/LEDGER_HANDOFF.md`.

### Arbitrage Lattice (`cursor/arbitrage-lattice-72de`)

Python CLI installed with a venv + editable install (see that branch's `README.md`):
`python3.12 -m venv .venv && ./.venv/bin/pip install -e .`. There is no test suite or
lint config in the branch; validate with `python -m compileall src`. Non-obvious caveats:

- There is **no local-only code path**. Every subcommand instantiates a Supabase and/or
  OpenAI client at startup, so even `list-leads` requires `SUPABASE_URL` + `SUPABASE_KEY`,
  and the `ingest-*` commands additionally require `OPENAI_API_KEY`. `prepare-payout` and
  approved transfers require `STRIPE_SECRET_KEY`. `--help` works without secrets. Set the
  rest (e.g. via `.env`, see `.env.example`) before attempting any real action.
- The schema in `db/schema.sql` needs the Postgres `vector` (pgvector) extension; apply it
  to your Supabase/Postgres database before running.
- After changing dependencies, reinstall inside the venv (`./.venv/bin/pip install -e .`).
