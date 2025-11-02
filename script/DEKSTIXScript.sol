// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "forge-std/Script.sol";
import "../src/DEKSTIX.sol";

contract DeployDEKSTIX is Script {
    function run() external returns (DEKSTIX) {
        vm.startBroadcast();
        
        DEKSTIX dekstix = new DEKSTIX();
        
        vm.stopBroadcast();
        
        return dekstix;
    }
}