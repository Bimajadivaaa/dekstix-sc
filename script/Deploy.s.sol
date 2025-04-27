// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/EventTicketingNFT.sol";

contract DeployScript is Script {
    function run() external {
        // Retrieve private key from environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Start broadcasting transactions
        vm.startBroadcast(deployerPrivateKey);

        // Deploy the main contract
        EventTicketingNFT eventTicketing = new EventTicketingNFT(vm.addr(deployerPrivateKey));
        
        // Set base URI (optional)
        // eventTicketing.setBaseURI("https://your-metadata-server.com/");

        vm.stopBroadcast();

        // Log the deployed addresses
        console.log("EventTicketingNFT deployed at:", address(eventTicketing));
    }
} 