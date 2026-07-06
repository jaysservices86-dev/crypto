// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "forge-std/console2.sol";
import "../src/interfaces/IAttestationConsumer.sol";
import "../src/registry/EpistemicLedgerRegistry.sol";

contract Demo is Script {
    address private constant ORACLE_FINALIZER = address(0xA11CE);

    function run() external {
        EpistemicLedgerRegistry registry = new EpistemicLedgerRegistry();

        bytes32 contentHash = keccak256("demo://c2pa/photo/factory-sector-7");
        uint256 expiryTimestamp = block.timestamp + 30 days;

        address[] memory validators = new address[](3);
        validators[0] = address(0x1001);
        validators[1] = address(0x1002);
        validators[2] = address(0x1003);

        bytes memory evidenceMetadata = abi.encode(
            "c2pa:demo-camera-signature",
            "gps:40.7128,-74.0060",
            "oracle-consensus:3-of-3",
            "claim:A factory explosion photo is authentic"
        );

        registry.setFinalizer(ORACLE_FINALIZER, true);

        vm.prank(ORACLE_FINALIZER);
        registry.finalizeAttestationWithEvidence(
            contentHash,
            IAttestationConsumer.AttestationStatus.Verified,
            9_700,
            expiryTimestamp,
            validators,
            evidenceMetadata
        );

        IAttestationConsumer.AttestationSummary memory summary = registry.getAttestationSummary(contentHash);
        IAttestationConsumer.Attestation memory attestation = registry.getAttestation(contentHash);

        console2.log("Epistemic Ledger demo");
        console2.log("---------------------");
        console2.log("Registry:", address(registry));
        console2.logBytes32("Content hash:", contentHash);
        console2.log("Status:", uint256(summary.status));
        console2.log("Confidence score:", summary.confidenceScore);
        console2.log("Valid:", registry.isAttestationValid(contentHash));
        console2.log("Validator count:", attestation.validatorCount);
        console2.log("Metadata bytes:", attestation.metadata.length);
        console2.log("Expiry timestamp:", summary.expiryTimestamp);
    }
}
