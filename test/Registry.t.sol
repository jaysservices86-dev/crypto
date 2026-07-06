// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/registry/EpistemicLedgerRegistry.sol";
import "../src/interfaces/IAttestationConsumer.sol";

contract RegistryTest is Test {
    EpistemicLedgerRegistry registry;

    bytes32 constant CONTENT_HASH = keccak256("test content");
    uint256 constant EXPIRY = 1_800_000_000;
    address constant ORACLE = address(0xA11CE);
    address constant UNAUTHORIZED = address(0xB0B);

    function setUp() public {
        registry = new EpistemicLedgerRegistry();
    }

    function testFinalizeAndRead() public {
        registry.finalizeAttestation(CONTENT_HASH, IAttestationConsumer.AttestationStatus.Verified, 9500, EXPIRY);

        IAttestationConsumer.AttestationSummary memory summary = registry.getAttestationSummary(CONTENT_HASH);
        assertEq(uint256(summary.status), uint256(IAttestationConsumer.AttestationStatus.Verified));
        assertEq(summary.confidenceScore, 9500);

        bool valid = registry.isAttestationValid(CONTENT_HASH);
        assertTrue(valid);

        bytes32[] memory hashes = new bytes32[](1);
        hashes[0] = CONTENT_HASH;
        IAttestationConsumer.AttestationSummary[] memory summaries = registry.getAttestationSummaries(hashes);
        assertEq(summaries.length, 1);
        assertEq(uint256(summaries[0].status), uint256(IAttestationConsumer.AttestationStatus.Verified));
    }

    function testInvalidAttestationReverts() public {
        vm.expectRevert(abi.encodeWithSelector(IAttestationConsumer.AttestationNotFound.selector, bytes32(0)));
        registry.getAttestation(bytes32(0));
    }

    function testExpiredStatus() public {
        registry.finalizeAttestation(
            CONTENT_HASH, IAttestationConsumer.AttestationStatus.Expired, 0, block.timestamp - 1
        );

        bool valid = registry.isAttestationValid(CONTENT_HASH);
        assertFalse(valid);
    }

    function testUnauthorizedFinalizerReverts() public {
        vm.prank(UNAUTHORIZED);
        vm.expectRevert(abi.encodeWithSelector(EpistemicLedgerRegistry.NotAuthorizedFinalizer.selector, UNAUTHORIZED));
        registry.finalizeAttestation(CONTENT_HASH, IAttestationConsumer.AttestationStatus.Verified, 9500, EXPIRY);
    }

    function testAuthorizedFinalizerCanStoreEvidence() public {
        registry.setFinalizer(ORACLE, true);

        address[] memory validators = new address[](2);
        validators[0] = address(0x1);
        validators[1] = address(0x2);
        bytes memory metadata = abi.encode("c2pa-anchor", "oracle-consensus-bundle");

        vm.prank(ORACLE);
        registry.finalizeAttestationWithEvidence(
            CONTENT_HASH, IAttestationConsumer.AttestationStatus.Verified, 9900, EXPIRY, validators, metadata
        );

        IAttestationConsumer.Attestation memory attestation = registry.getAttestation(CONTENT_HASH);
        assertEq(attestation.validatorCount, 2);
        assertEq(attestation.validators[0], validators[0]);
        assertEq(attestation.validators[1], validators[1]);
        assertEq(attestation.metadata, metadata);
    }

    function testVerifiedAttestationPastExpiryIsInvalid() public {
        vm.warp(1_000_000);
        uint256 expiredAt = block.timestamp - 1;
        registry.finalizeAttestation(CONTENT_HASH, IAttestationConsumer.AttestationStatus.Verified, 9500, expiredAt);

        bool valid = registry.isAttestationValid(CONTENT_HASH);
        assertFalse(valid);
    }
}
