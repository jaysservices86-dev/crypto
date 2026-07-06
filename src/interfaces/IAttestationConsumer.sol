// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

interface IAttestationConsumer {
    error AttestationNotFound(bytes32 contentHash);
    error AttestationNotFinalized(bytes32 contentHash);
    error AttestationExpired(bytes32 contentHash);
    error NotAuthorizedConsumer(address consumer, bytes32 contentHash);

    enum AttestationStatus {
        None,
        Pending,
        Verified,
        Debunked,
        Disputed,
        Hypothesis,
        Expired
    }

    struct Attestation {
        bytes32 contentHash;
        AttestationStatus status;
        uint256 confidenceScore;
        uint256 validatorCount;
        uint256 timestamp;
        uint256 expiryTimestamp;
        address[] validators;
        bytes metadata;
    }

    struct AttestationSummary {
        bytes32 contentHash;
        AttestationStatus status;
        uint256 confidenceScore;
        uint256 expiryTimestamp;
    }

    event AttestationFinalized(
        bytes32 indexed contentHash, AttestationStatus status, uint256 confidenceScore, uint256 timestamp
    );
    event AttestationMarkedExpired(bytes32 indexed contentHash, uint256 expiryTimestamp);

    function getAttestation(bytes32 contentHash) external view returns (Attestation memory);
    function getAttestationSummary(bytes32 contentHash) external view returns (AttestationSummary memory);
    function isAttestationValid(bytes32 contentHash) external view returns (bool);
    function getAttestationStatus(bytes32 contentHash) external view returns (AttestationStatus);
    function getAttestationSummaries(bytes32[] calldata contentHashes)
        external
        view
        returns (AttestationSummary[] memory);
    function areAttestationsValid(bytes32[] calldata contentHashes) external view returns (bool[] memory);
    function getConfidenceScore(bytes32 contentHash) external view returns (uint256);
    function getExpiryTimestamp(bytes32 contentHash) external view returns (uint256);
}
