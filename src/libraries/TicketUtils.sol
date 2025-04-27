// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/TicketStructs.sol";
import "../interfaces/ITicketTypes.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

library TicketUtils {
    using Strings for uint256;

    function generateUniqueCode(
        uint256 tokenId, 
        uint256 eventId,
        uint256 codeId,
        address sender,
        uint256 timestamp
    ) internal pure returns (string memory) {
        uint256 random = uint256(keccak256(abi.encodePacked(
            tokenId,
            eventId,
            timestamp,
            sender,
            codeId
        )));
        
        return string(abi.encodePacked(
            "EVT",
            eventId.toString(),
            "-TKT",
            tokenId.toString(),
            "-",
            (random % 1000000).toString()
        ));
    }

    function toHexString(uint256 value, uint256 length) internal pure returns (string memory) {
        bytes memory buffer = new bytes(2 * length + 2);
        buffer[0] = "0";
        buffer[1] = "x";
        for (uint256 i = 2 * length + 1; i > 1; --i) {
            uint8 digit = uint8(value & 0xf);
            buffer[i] = bytes1(digit + (digit < 10 ? 48 : 87));
            value >>= 4;
        }
        return string(buffer);
    }
}