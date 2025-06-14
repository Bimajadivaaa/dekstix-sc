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
        uint96 purchaseTime;
    }

    struct CodeStatus {
        bool isValid;
        bool isUsed;
        uint256 tokenId;
        address owner;
    }

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

    struct TicketWithNFT {
        uint256 tokenId;
        uint256 eventId;
        string eventName;
        ITicketTypes.TicketType ticketType;
        string tokenURI;
    }
}