// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../structs/EventStructs.sol";
import "../structs/TicketStructs.sol";
import "./ITicketTypes.sol";

interface IEventTicketingNFT {
    event EventCreated(uint256 indexed eventId, string name, uint256 date);
    event TicketPriceSet(uint256 indexed eventId, ITicketTypes.TicketType ticketType, uint256 price);
    event TicketMinted(uint256 indexed tokenId, uint256 indexed eventId, address indexed owner, ITicketTypes.TicketType ticketType);
    event TicketPurchased(uint256 indexed tokenId, uint256 indexed eventId, address indexed buyer, uint256 price);
    event TicketUsed(uint256 indexed tokenId, uint256 indexed eventId);
    event CodeVerified(uint256 indexed tokenId, uint256 indexed eventId, bool isValid, bool isUsed);

    function createEvent(
        string memory name,
        string memory description,
        string memory location,
        string memory imageURI,
        uint256 date,
        uint256 startTime,
        uint256 endTime,
        uint256 totalTickets,
        string[] memory speakers
    ) external returns (uint256);

    function setTicketPrice(uint256 eventId, ITicketTypes.TicketType ticketType, uint256 price) external;
    function getTicketPrice(uint256 eventId, ITicketTypes.TicketType ticketType) external view returns (uint256);
    function getEventInfo(uint256 eventId) external view returns (EventStructs.EventDetails memory);
    function toggleEventStatus(uint256 eventId) external;
    function mintTicket(uint256 eventId, ITicketTypes.TicketType ticketType, string memory tokenURI) external returns (uint256);
    function buyTicket(uint256 tokenId) external payable;
    function getListedTickets(uint256 eventId) external view returns (uint256[] memory);
    function useTicket(uint256 tokenId) external;
    function verifyCode(string memory code) external returns (bool);
    function getTicketCode(uint256 tokenId) external view returns (string memory);
    function isTicketUsed(uint256 tokenId) external view returns (bool);
    function getTicketType(uint256 tokenId) external view returns (ITicketTypes.TicketType);
    function getTicketsByTypeAndEvent(uint256 eventId, ITicketTypes.TicketType ticketType) external view returns (uint256[] memory);
    function getAllEvents() external view returns (EventStructs.EventDetails[] memory);
    function getActiveEvents() external view returns (EventStructs.EventDetails[] memory);
    function getMyNFTs() external view returns (TicketStructs.TicketWithNFT[] memory);
    function isEventExpired(uint256 eventId) external view returns (bool);
    function getMyPurchaseHistory() external view returns (TicketStructs.PurchaseHistory[] memory);
    function mintAndBuyVIPTicket(uint256 eventId, string memory tokenURI) external payable returns (uint256);
    function batchMintTickets(
        uint256 eventId,
        ITicketTypes.TicketType ticketType,
        string memory tokenURI,
        uint256 quantity
    ) external returns (uint256[] memory);
    function isTicketCodeExpired(uint256 tokenId) external view returns (bool);
    
    function getEventTicketStock(uint256 eventId) external view returns (
        uint256 totalTickets,
        uint256 remainingTickets,
        uint256 soldTickets
    );
    
    function getEventTicketStockByType(uint256 eventId, ITicketTypes.TicketType ticketType) external view returns (
        uint256 totalTickets,
        uint256 remainingTickets,
        uint256 soldTickets
    );
}