# Epistemic Ledger Foundry

Foundry contracts for an Epistemic Ledger attestation registry, adapter, mocks, and deployment script.

## Business-model alignment

This repository implements the on-chain consumption layer described in the Epistemic Ledger business model:

- Finalized truth ratings are stored as queryable attestation summaries for B2B Trust API consumers.
- Attestations can retain oracle validator addresses and metadata bytes for provenance, consensus evidence, C2PA anchors, or off-chain evidence bundles.
- Validity checks recognize only `Verified` and `Hypothesis` attestations that have not expired.
- The adapter contract gives downstream applications a stable read surface over the registry.

The broader ingestion, deterministic AI triage, staking/slashing, challenger rewards, API billing, and hardware licensing systems remain separate modules to be implemented around this registry.

## Layout

- `src/interfaces/IAttestationConsumer.sol` - attestation read interface and shared types.
- `src/registry/EpistemicLedgerRegistry.sol` - registry for finalized attestation summaries and evidence metadata.
- `src/adapters/AttestationConsumer.sol` - base consumer adapter that delegates reads to the registry.
- `src/mocks/` - mock token and oracle contracts.
- `script/Deploy.s.sol` - deployment script for the registry.
- `test/Registry.t.sol` - uploaded registry tests.

## Commands

```sh
forge build
forge test
```
