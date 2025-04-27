// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/EventStructs.sol";

library EventUtils {
    function getEventDetails(
        mapping(uint256 => EventStructs.EventStorage) storage events,
        uint256 eventId
    ) internal view returns (EventStructs.EventDetails memory) {
        EventStructs.EventStorage storage eventInfo = events[eventId];
        
        return EventStructs.EventDetails({
            eventId: eventId,
            name: eventInfo.name,
            description: eventInfo.description,
            location: eventInfo.location,
            imageURI: eventInfo.imageURI,
            date: uint256(eventInfo.date),
            startTime: uint256(eventInfo.startTime),
            endTime: uint256(eventInfo.endTime),
            isActive: eventInfo.isActive,
            remainingTickets: uint256(eventInfo.remainingTickets),
            totalTickets: uint256(eventInfo.totalTickets)
        });
    }
}