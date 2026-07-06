// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../interfaces/IAttestationConsumer.sol";

abstract contract AttestationConsumer is IAttestationConsumer {
    address public immutable EPISTEMIC_LEDGER_REGISTRY;
    address public immutable ATTESTATION_SOURCE;

    error NotAllowedAttestationSource();

    modifier onlyAttestationSource() {
        if (msg.sender != ATTESTATION_SOURCE) revert NotAllowedAttestationSource();
        _;
    }

    constructor(address registry, address source) {
        EPISTEMIC_LEDGER_REGISTRY = registry;
        ATTESTATION_SOURCE = source;
    }

    function onNewAttestation(bytes32 contentHash, AttestationStatus status) external virtual onlyAttestationSource {
        _onNewAttestation(contentHash, status);
    }

    function _onNewAttestation(bytes32 contentHash, AttestationStatus status) internal virtual {}

    function getAttestation(bytes32 contentHash) external view virtual override returns (Attestation memory) {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).getAttestation(contentHash);
    }

    function getAttestationSummary(bytes32 contentHash)
        external
        view
        virtual
        override
        returns (AttestationSummary memory)
    {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).getAttestationSummary(contentHash);
    }

    function isAttestationValid(bytes32 contentHash) external view virtual override returns (bool) {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).isAttestationValid(contentHash);
    }

    function getAttestationStatus(bytes32 contentHash) external view virtual override returns (AttestationStatus) {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).getAttestationStatus(contentHash);
    }

    function getAttestationSummaries(bytes32[] calldata contentHashes)
        external
        view
        virtual
        override
        returns (AttestationSummary[] memory)
    {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).getAttestationSummaries(contentHashes);
    }

    function areAttestationsValid(bytes32[] calldata contentHashes)
        external
        view
        virtual
        override
        returns (bool[] memory)
    {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).areAttestationsValid(contentHashes);
    }

    function getConfidenceScore(bytes32 contentHash) external view virtual override returns (uint256) {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).getConfidenceScore(contentHash);
    }

    function getExpiryTimestamp(bytes32 contentHash) external view virtual override returns (uint256) {
        return IAttestationConsumer(EPISTEMIC_LEDGER_REGISTRY).getExpiryTimestamp(contentHash);
    }
}
