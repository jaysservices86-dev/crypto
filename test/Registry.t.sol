// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Test.sol";
import "../src/registry/EpistemicLedgerRegistry.sol";
import "../src/interfaces/IAttestationConsumer.sol";

contract RegistryTest is Test {
    EpistemicLedgerRegistry registry;

    bytes32 constant CONTENT_HASH = keccak256("test content");
    uint256 constant EXPIRY = 1_800_000_000;

    function setUp() public {
        registry = new EpistemicLedgerRegistry();
    }

    function testFinalizeAndRead() public {
        registry.finalizeAttestation(
            CONTENT_HASH,
            IAttestationConsumer.AttestationStatus.Verified,
            9500,
            EXPIRY
        );

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
            CONTENT_HASH,
            IAttestationConsumer.AttestationStatus.Expired,
            0,
            block.timestamp - 1
        );

        bool valid = registry.isAttestationValid(CONTENT_HASH);
        assertFalse(valid);
    }
}
