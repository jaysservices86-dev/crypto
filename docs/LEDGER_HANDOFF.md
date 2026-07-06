# Epistemic Ledger handoff

## Current status

The repository currently contains a working Foundry MVP for the Epistemic Ledger on-chain registry/read layer.

Implemented:

- `EpistemicLedgerRegistry` stores finalized attestation summaries.
- Owner-approved finalizers can finalize attestations.
- Finalized attestations can include validator addresses and opaque evidence metadata bytes.
- Validity checks return true only for non-expired `Verified` or `Hypothesis` attestations.
- A local Foundry demo shows the end-to-end registry flow.
- Registry tests cover finalization, expiry, evidence storage, and unauthorized finalizer rejection.

Verified commands:

```sh
forge build
forge test
forge script script/Demo.s.sol
```

Known warning:

- Foundry warns about `block.timestamp` in expiry checks. This is expected for coarse attestation expiry. If expiry becomes economically sensitive, replace direct timestamp logic with a stronger time/source policy.

## Important files

- `src/interfaces/IAttestationConsumer.sol` - shared attestation types and read interface.
- `src/registry/EpistemicLedgerRegistry.sol` - on-chain registry and finalizer access control.
- `src/adapters/AttestationConsumer.sol` - base adapter for consumers that delegate reads to the registry.
- `script/Demo.s.sol` - local simulation demo.
- `test/Registry.t.sol` - registry test coverage.
- `README.md` - user-facing run/demo instructions.

## How to run locally

```sh
git submodule update --init --recursive
forge build
forge test
forge script script/Demo.s.sol
```

Expected demo result includes:

- `Status: 2` (`Verified`)
- `Confidence score: 9700`
- `Valid: true`
- `Validator count: 3`
- non-zero metadata bytes

## Next useful work

The business model describes a larger system. The highest-value next modules are:

1. **Oracle/staking module**
   - Register validators.
   - Require stake before finalization participation.
   - Track validator voting weight and lock periods.
   - Route only successful consensus outcomes into `EpistemicLedgerRegistry`.

2. **Challenge/dispute module**
   - Allow challengers to open cases against finalized attestations.
   - Track challenge bonds and evidence metadata.
   - Resolve challenges and update registry status to `Debunked`, `Disputed`, or `Expired`.

3. **Evidence/provenance schema**
   - Replace opaque metadata convention with a documented encoded schema.
   - Prefer hashes, CIDs, or signed evidence bundle digests over large on-chain payloads.
   - Include C2PA signature anchors, sensor metadata hash, oracle vote bundle hash, and source URI/CID.

4. **API demo**
   - Add a small service that queries registry summaries by content hash.
   - Return status, confidence, expiry, and validity in a JSON response.
   - Keep writes on-chain and reads cacheable.

## Cautions

- The registry is intentionally not the complete protocol; it is the final read surface.
- Do not reopen unrestricted public finalization. Writes should go through owner-approved finalizers or a future consensus controller.
- Avoid storing full media or large evidence directly on-chain.
- Keep `finalizeAttestation(...)` for simple compatibility, but prefer `finalizeAttestationWithEvidence(...)` for realistic flows.
