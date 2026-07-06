// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/registry/EpistemicLedgerRegistry.sol";

contract Deploy is Script {
    function run() external {
        vm.startBroadcast();
        new EpistemicLedgerRegistry();
        vm.stopBroadcast();
    }
}
