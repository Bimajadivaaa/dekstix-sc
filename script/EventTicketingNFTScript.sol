// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "forge-std/Script.sol";
import "../src/EventTicketingNFT.sol";

contract DeployEventTicketingNFT is Script {
    function run() external {
        // Get deployer private key
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        address deployer = vm.addr(deployerPrivateKey);
        
        console.log("Deploying contracts with address:", deployer);
        
        // Start broadcasting
        vm.startBroadcast(deployerPrivateKey);

        // Deploy EventTicketingNFT
        EventTicketingNFT eventTicketing = new EventTicketingNFT(deployer);
        
        // Set base URI for NFT metadata
        // eventTicketing.setBaseURI("https://api.dekstix.com/metadata/");

        // Stop broadcasting
        vm.stopBroadcast();

        // Log deployment info
        console.log("Deployment completed!");
        console.log("EventTicketingNFT deployed at:", address(eventTicketing));
        console.log("Owner address:", deployer);
        
        // Verify deployment
        console.log("Verify contract on Etherscan with:");
        console.log("forge verify-contract", address(eventTicketing), "EventTicketingNFT", "--chain-id 11155111");
    }
}