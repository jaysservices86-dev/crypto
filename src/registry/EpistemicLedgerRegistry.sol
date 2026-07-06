// SPDX-License-Identifier: BUSL-1.1
pragma solidity ^0.8.20;

import "../interfaces/IAttestationConsumer.sol";

contract EpistemicLedgerRegistry is IAttestationConsumer {
    address public owner;

    mapping(bytes32 => Attestation) private _attestations;
    mapping(bytes32 => AttestationSummary) private _summaries;
    mapping(address => bool) public isFinalizer;

    error NotRegistryOwner(address caller);
    error NotAuthorizedFinalizer(address caller);

    event FinalizerUpdated(address indexed finalizer, bool allowed);

    modifier onlyOwner() {
        if (msg.sender != owner) revert NotRegistryOwner(msg.sender);
        _;
    }

    modifier onlyFinalizer() {
        if (msg.sender != owner && !isFinalizer[msg.sender]) revert NotAuthorizedFinalizer(msg.sender);
        _;
    }

    constructor() {
        owner = msg.sender;
    }

    function setFinalizer(address finalizer, bool allowed) external onlyOwner {
        isFinalizer[finalizer] = allowed;
        emit FinalizerUpdated(finalizer, allowed);
    }

    function finalizeAttestation(
        bytes32 contentHash,
        AttestationStatus status,
        uint256 confidenceScore,
        uint256 expiryTimestamp
    ) external onlyFinalizer {
        address[] memory validators = new address[](0);
        _finalizeAttestation(contentHash, status, confidenceScore, expiryTimestamp, validators, new bytes(0));
    }

    function finalizeAttestationWithEvidence(
        bytes32 contentHash,
        AttestationStatus status,
        uint256 confidenceScore,
        uint256 expiryTimestamp,
        address[] calldata validators,
        bytes calldata metadata
    ) external onlyFinalizer {
        address[] memory validatorCopy = new address[](validators.length);
        for (uint256 i = 0; i < validators.length; i++) {
            validatorCopy[i] = validators[i];
        }

        bytes memory metadataCopy = metadata;
        _finalizeAttestation(contentHash, status, confidenceScore, expiryTimestamp, validatorCopy, metadataCopy);
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

    function _finalizeAttestation(
        bytes32 contentHash,
        AttestationStatus status,
        uint256 confidenceScore,
        uint256 expiryTimestamp,
        address[] memory validators,
        bytes memory metadata
    ) internal {
        Attestation storage attestation = _attestations[contentHash];
        attestation.contentHash = contentHash;
        attestation.status = status;
        attestation.confidenceScore = confidenceScore;
        attestation.validatorCount = validators.length;
        attestation.timestamp = block.timestamp;
        attestation.expiryTimestamp = expiryTimestamp;
        attestation.metadata = metadata;

        delete attestation.validators;
        for (uint256 i = 0; i < validators.length; i++) {
            attestation.validators.push(validators[i]);
        }

        _summaries[contentHash] = AttestationSummary({
            contentHash: contentHash, status: status, confidenceScore: confidenceScore, expiryTimestamp: expiryTimestamp
        });

        emit AttestationFinalized(contentHash, status, confidenceScore, block.timestamp);
        if (status == AttestationStatus.Expired || _isExpired(expiryTimestamp)) {
            emit AttestationMarkedExpired(contentHash, expiryTimestamp);
        }
    }

    function _isAttestationValid(bytes32 contentHash) internal view returns (bool) {
        AttestationSummary memory summary = _summaries[contentHash];
        bool validStatus =
            summary.status == AttestationStatus.Verified || summary.status == AttestationStatus.Hypothesis;
        return validStatus && !_isExpired(summary.expiryTimestamp);
    }

    function _isExpired(uint256 expiryTimestamp) internal view returns (bool) {
        return expiryTimestamp != 0 && block.timestamp >= expiryTimestamp;
    }
}
