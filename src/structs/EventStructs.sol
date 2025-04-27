// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITicketTypes.sol";

library EventStructs {
    // Optimize storage by packing related variables
    struct EventStorage {
        string name;
        string description;
        string location;
        string imageURI;
        uint96 date; // Reduced from uint256 to uint96 (still good until year 2200+)
        uint96 startTime;
        uint96 endTime;
        bool isActive;
        uint32 remainingTickets; // Changed from uint256 to uint32 (max 4.2 billion tickets)
        uint32 totalTickets;
        mapping(uint8 => uint256) ticketPrices;
    }

    // Struct for returning event details
    struct EventDetails {
        uint256 eventId;
        string name;
        string description;
        string location;
        string imageURI;
        uint256 date;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 remainingTickets;
        uint256 totalTickets;
    }
}