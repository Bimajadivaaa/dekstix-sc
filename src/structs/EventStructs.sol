// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../interfaces/ITicketTypes.sol";

library EventStructs {
    struct EventStorage {
        string name;
        string description;
        string location;
        string imageURI;
        uint96 date;
        uint96 startTime;
        uint96 endTime;
        bool isActive;
        uint32 remainingTickets;
        uint32 totalTickets;
        uint32 soldTickets;
        string[] speakers;
        mapping(uint8 => uint256) ticketPrices;
    }

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
        uint256 soldTickets;
        string[] speakers;
    }
}