// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import {Script, console} from "forge-std/Script.sol";
import {EventTicketingNFT} from "../src/EventTicketingNFT.sol";

contract DeployEventTicketingNFT is Script {
    function run() external {
        // Ambil private key dari environment variable
        uint256 deployerPrivateKey = vm.envUint("PRIVATE_KEY");
        
        // Ambil owner address dari environment variable atau gunakan address dari private key
        address initialOwner;
        try vm.envAddress("OWNER_ADDRESS") returns (address ownerAddr) {
            initialOwner = ownerAddr;
        } catch {
            // Jika OWNER_ADDRESS tidak diatur, gunakan address dari private key
            initialOwner = vm.addr(deployerPrivateKey);
        }
        
        console.log("Deploying EventTicketingNFT with owner:", initialOwner);
        
        // Mulai broadcast transaksi
        vm.startBroadcast(deployerPrivateKey);
        
        // Deploy kontrak
        EventTicketingNFT nft = new EventTicketingNFT(initialOwner);
        
        // Akhiri broadcast
        vm.stopBroadcast();
        
        console.log("EventTicketingNFT deployed at:", address(nft));
    }
}