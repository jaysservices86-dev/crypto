# Epistemic Ledger Foundry

Foundry contracts for an Epistemic Ledger attestation registry, adapter, mocks, and deployment script.

## Layout

- `src/interfaces/IAttestationConsumer.sol` - attestation read interface and shared types.
- `src/registry/EpistemicLedgerRegistry.sol` - registry for finalized attestation summaries.
- `src/adapters/AttestationConsumer.sol` - base consumer adapter that delegates reads to the registry.
- `src/mocks/` - mock token and oracle contracts.
- `script/Deploy.s.sol` - deployment script for the registry.
- `test/Registry.t.sol` - uploaded registry tests.

## Commands

```sh
forge build
forge test
```
