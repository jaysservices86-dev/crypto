// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../interfaces/IAttestationConsumer.sol";

contract EpistemicLedgerRegistry is IAttestationConsumer {
    mapping(bytes32 => Attestation) private _attestations;
    mapping(bytes32 => AttestationSummary) private _summaries;

    function finalizeAttestation(
        bytes32 contentHash,
        AttestationStatus status,
        uint256 confidenceScore,
        uint256 expiryTimestamp
    ) external {
        Attestation storage attestation = _attestations[contentHash];
        attestation.contentHash = contentHash;
        attestation.status = status;
        attestation.confidenceScore = confidenceScore;
        attestation.validatorCount = 0;
        attestation.timestamp = block.timestamp;
        attestation.expiryTimestamp = expiryTimestamp;

        _summaries[contentHash] = AttestationSummary({
            contentHash: contentHash,
            status: status,
            confidenceScore: confidenceScore,
            expiryTimestamp: expiryTimestamp
        });

        emit AttestationFinalized(contentHash, status, confidenceScore, block.timestamp);
    }

    function getAttestation(bytes32 contentHash) external view override returns (Attestation memory) {
        if (_attestations[contentHash].contentHash == bytes32(0)) {
            revert AttestationNotFound(contentHash);
        }

        return _attestations[contentHash];
    }

    function getAttestationSummary(bytes32 contentHash) external view override returns (AttestationSummary memory) {
        return _summaries[contentHash];
    }

    function isAttestationValid(bytes32 contentHash) external view override returns (bool) {
        return _isAttestationValid(contentHash);
    }

    function getAttestationStatus(bytes32 contentHash) external view override returns (AttestationStatus) {
        return _summaries[contentHash].status;
    }

    function getAttestationSummaries(bytes32[] calldata contentHashes)
        external
        view
        override
        returns (AttestationSummary[] memory)
    {
        AttestationSummary[] memory results = new AttestationSummary[](contentHashes.length);

        for (uint256 i = 0; i < contentHashes.length; i++) {
            results[i] = _summaries[contentHashes[i]];
        }

        return results;
    }

    function areAttestationsValid(bytes32[] calldata contentHashes) external view override returns (bool[] memory) {
        bool[] memory results = new bool[](contentHashes.length);

        for (uint256 i = 0; i < contentHashes.length; i++) {
            results[i] = _isAttestationValid(contentHashes[i]);
        }

        return results;
    }

    function getConfidenceScore(bytes32 contentHash) external view override returns (uint256) {
        return _summaries[contentHash].confidenceScore;
    }

    function getExpiryTimestamp(bytes32 contentHash) external view override returns (uint256) {
        return _summaries[contentHash].expiryTimestamp;
    }

    function _isAttestationValid(bytes32 contentHash) internal view returns (bool) {
        AttestationStatus status = _summaries[contentHash].status;
        return status == AttestationStatus.Verified || status == AttestationStatus.Hypothesis;
    }
}
