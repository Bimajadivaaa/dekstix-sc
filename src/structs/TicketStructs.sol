// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITicketTypes.sol";

library TicketStructs {
    struct Ticket {
        uint256 eventId;
        ITicketTypes.TicketType ticketType;
        bool isListed;
        bool isUsed;
        bytes32 uniqueCodeHash;
        address purchaser;
        uint96 purchaseTime; // Changed from uint256 to uint96
    }

    struct CodeStatus {
        bool isValid;
        bool isUsed;
        uint256 tokenId;
        address owner;
    }

    // Struct for user's purchase history
    struct PurchaseHistory {
        uint256 tokenId;
        uint256 eventId;
        string eventName;
        uint256 eventDate;
        bool isExpired;
        bool isUsed;
        ITicketTypes.TicketType ticketType;
        string ticketCode;
        string tokenURI;
    }

    // Struct for ticket with NFT data
    struct TicketWithNFT {
        uint256 tokenId;
        uint256 eventId;
        string eventName;
        ITicketTypes.TicketType ticketType;
        string tokenURI;
    }
}