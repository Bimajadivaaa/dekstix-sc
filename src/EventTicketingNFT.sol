// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

import "./interfaces/IEventTicketingNFT.sol";
import "./interfaces/ITicketTypes.sol";
import "./libraries/TicketUtils.sol";
import "./libraries/EventUtils.sol";
import "./structs/EventStructs.sol";
import "./structs/TicketStructs.sol";

// Custom errors
error NotAuthorized();
error TicketNotUsed();
error EventNotActive();
error InvalidCode();
error EventNotExist();
error TicketAlreadyUsed();
error InsufficientPayment();
error NoCodeGenerated();
error TicketNotAvailable();

contract EventTicketingNFT is ERC721URIStorage, Ownable, IEventTicketingNFT {
    using Counters for Counters.Counter;
    using Strings for uint256;
    using EventUtils for mapping(uint256 => EventStructs.EventStorage);
    using TicketUtils for uint256;
    
    Counters.Counter private _eventIds;
    Counters.Counter private _tokenIds;
    Counters.Counter private _codeIds;

    // Base URI for metadata
    string private _baseTokenURI;

    // Mapping from eventId to struct Event
    mapping(uint256 => EventStructs.EventStorage) private events;
    
    // Mapping from tokenId to ticket information
    mapping(uint256 => TicketStructs.Ticket) public tickets;
    
    // Mapping from code hash to code status
    mapping(bytes32 => TicketStructs.CodeStatus) private codes;
    
    // Mapping from tokenId to ticket code
    mapping(uint256 => string) private ticketCodes;

    constructor(address initialOwner) 
        ERC721("Event Ticket", "TCKT")
        Ownable(initialOwner)
    {}

     modifier onlyValidEvent(uint256 eventId) {
        if (eventId == 0 || eventId > _eventIds.current()) revert EventNotExist();
        _;
    }

    modifier onlyValidTicket(uint256 tokenId) {
        if (tokenId == 0 || tokenId > _tokenIds.current()) revert EventNotExist();
        _;
    }

    function createEvent(
        string memory name,
        string memory description,
        string memory location,
        string memory imageURI,
        uint256 date,
        uint256 startTime,
        uint256 endTime,
        uint256 totalTickets
    ) public override onlyOwner returns (uint256) {
        _eventIds.increment();
        uint256 newEventId = _eventIds.current();
        
        EventStructs.EventStorage storage newEvent = events[newEventId];
        newEvent.name = name;
        newEvent.description = description;
        newEvent.location = location;
        newEvent.imageURI = imageURI;
        newEvent.date = uint96(date);
        newEvent.startTime = uint96(startTime);
        newEvent.endTime = uint96(endTime);
        newEvent.isActive = true;
        newEvent.remainingTickets = uint32(totalTickets);
        newEvent.totalTickets = uint32(totalTickets);
        
        // Set default prices for all ticket types (in wei)
        newEvent.ticketPrices[uint8(ITicketTypes.TicketType.STANDARD)] = 0.0001 ether;
        newEvent.ticketPrices[uint8(ITicketTypes.TicketType.PREMIUM)] = 0.0002 ether;
        newEvent.ticketPrices[uint8(ITicketTypes.TicketType.VIP)] = 0.0003 ether;
        
        emit EventCreated(newEventId, name, date);
        return newEventId;
    }

    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }

    function setTicketPrice(uint256 eventId, ITicketTypes.TicketType ticketType, uint256 price) external override onlyOwner {
        if (eventId > _eventIds.current()) revert EventNotExist();
        if (!events[eventId].isActive) revert EventNotActive();
        
        events[eventId].ticketPrices[uint8(ticketType)] = price;
        emit TicketPriceSet(eventId, ticketType, price);
    }

    function getTicketPrice(uint256 eventId, ITicketTypes.TicketType ticketType) external view override returns (uint256) {
        if (eventId > _eventIds.current()) revert EventNotExist();
        return events[eventId].ticketPrices[uint8(ticketType)];
    }

    function getEventInfo(uint256 eventId) external view override returns (EventStructs.EventDetails memory) {
        if (eventId > _eventIds.current()) revert EventNotExist();
        return events.getEventDetails(eventId);
    }

    function toggleEventStatus(uint256 eventId) external override onlyOwner {
        if (eventId > _eventIds.current()) revert EventNotExist();
        events[eventId].isActive = !events[eventId].isActive;
    }

    function mintTicket(uint256 eventId, ITicketTypes.TicketType ticketType, string memory tokenURI) external override onlyOwner returns (uint256) {
        if (eventId > _eventIds.current()) revert EventNotExist();
        if (!events[eventId].isActive) revert EventNotActive();
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        if (bytes(tokenURI).length > 0) {
            _setTokenURI(newTokenId, tokenURI);
        }

        tickets[newTokenId] = TicketStructs.Ticket({
            eventId: eventId,
            ticketType: ticketType,
            isListed: true,
            isUsed: false,
            uniqueCodeHash: bytes32(0),
            purchaser: address(0),
            purchaseTime: 0
        });

        emit TicketMinted(newTokenId, eventId, msg.sender, ticketType);
        return newTokenId;
    }

    function buyTicket(uint256 tokenId) external override payable {
        if (tokenId > _tokenIds.current()) revert EventNotExist();
        if (!tickets[tokenId].isListed) revert TicketNotAvailable();
        if (tickets[tokenId].isUsed) revert TicketAlreadyUsed();
        
        uint256 eventId = tickets[tokenId].eventId;
        if (!events[eventId].isActive) revert EventNotActive();
        
        uint256 price = events[eventId].ticketPrices[uint8(tickets[tokenId].ticketType)];
        if (msg.value < price) revert InsufficientPayment();

        address payable owner = payable(ownerOf(tokenId));
        owner.transfer(msg.value);

        _transfer(owner, msg.sender, tokenId);
        tickets[tokenId].isListed = false;
        tickets[tokenId].purchaser = msg.sender;
        tickets[tokenId].purchaseTime = uint96(block.timestamp);
        
        events[eventId].remainingTickets--;

        emit TicketPurchased(tokenId, eventId, msg.sender, msg.value);
    }

    function getListedTickets(uint256 eventId) external view override returns (uint256[] memory) {
        uint256 totalSupply = _tokenIds.current();
        uint256 listedCount = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].eventId == eventId && tickets[i].isListed && !tickets[i].isUsed) {
                listedCount++;
            }
        }

        uint256[] memory listedTickets = new uint256[](listedCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].eventId == eventId && tickets[i].isListed && !tickets[i].isUsed) {
                listedTickets[currentIndex] = i;
                currentIndex++;
            }
        }

        return listedTickets;
    }

    function useTicket(uint256 tokenId) external override {
        if (ownerOf(tokenId) != msg.sender) revert NotAuthorized();
        if (tickets[tokenId].isUsed) revert TicketAlreadyUsed();
        
        uint256 eventId = tickets[tokenId].eventId;
        if (!events[eventId].isActive) revert EventNotActive();

        _codeIds.increment();
        string memory uniqueCode = TicketUtils.generateUniqueCode(
            tokenId,
            eventId,
            _codeIds.current(),
            msg.sender,
            block.timestamp
        );
        
        bytes32 codeHash = keccak256(abi.encodePacked(uniqueCode));
        
        tickets[tokenId].uniqueCodeHash = codeHash;
        tickets[tokenId].isUsed = true;
        ticketCodes[tokenId] = uniqueCode;
        
        codes[codeHash] = TicketStructs.CodeStatus({
            isValid: true,
            isUsed: false,
            tokenId: tokenId,
            owner: msg.sender
        });

        emit TicketUsed(tokenId, eventId);
    }

    function verifyCode(string memory code) external override onlyOwner returns (bool) {
        bytes32 codeHash = keccak256(abi.encodePacked(code));
        TicketStructs.CodeStatus storage status = codes[codeHash];
        
        if (!status.isValid) revert InvalidCode();
        if (status.isUsed) revert TicketAlreadyUsed();
        
        uint256 tokenId = status.tokenId;
        uint256 eventId = tickets[tokenId].eventId;

        status.isUsed = true;
        
        emit CodeVerified(tokenId, eventId, true, true);
        return true;
    }

    function getTicketCode(uint256 tokenId) external view override returns (string memory) {
        if (tokenId > _tokenIds.current()) revert EventNotExist();
        
        bool isOwner = ownerOf(tokenId) == msg.sender;
        bool isPurchaser = tickets[tokenId].purchaser == msg.sender;
        if (!isOwner && !isPurchaser) revert NotAuthorized();
        
        if (!tickets[tokenId].isUsed) revert TicketNotUsed();
        
        bytes memory code = bytes(ticketCodes[tokenId]);
        if (code.length == 0) revert NoCodeGenerated();
        
        return ticketCodes[tokenId];
    }

    function isTicketUsed(uint256 tokenId) external view override returns (bool) {
        return tickets[tokenId].isUsed;
    }

    function getTicketType(uint256 tokenId) external view override returns (ITicketTypes.TicketType) {
        return tickets[tokenId].ticketType;
    }

    function getTicketsByTypeAndEvent(uint256 eventId, ITicketTypes.TicketType ticketType) external view override returns (uint256[] memory) {
        uint256 totalSupply = _tokenIds.current();
        uint256 typeCount = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].eventId == eventId && 
                tickets[i].ticketType == ticketType && 
                tickets[i].isListed) {
                typeCount++;
            }
        }

        uint256[] memory filteredTickets = new uint256[](typeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].eventId == eventId && 
                tickets[i].ticketType == ticketType && 
                tickets[i].isListed) {
                filteredTickets[currentIndex] = i;
                currentIndex++;
            }
        }

        return filteredTickets;
    }

    function getAllEvents() external view override returns (EventStructs.EventDetails[] memory) {
        uint256 eventCount = _eventIds.current();
        EventStructs.EventDetails[] memory allEvents = new EventStructs.EventDetails[](eventCount);
        
        for (uint256 i = 1; i <= eventCount; i++) {
            allEvents[i-1] = events.getEventDetails(i);
        }
        
        return allEvents;
    }

    function getActiveEvents() external view override returns (EventStructs.EventDetails[] memory) {
        uint256 eventCount = _eventIds.current();
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeCount++;
            }
        }
        
        EventStructs.EventDetails[] memory activeEvents = new EventStructs.EventDetails[](activeCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeEvents[currentIndex] = events.getEventDetails(i);
                currentIndex++;
            }
        }
        
        return activeEvents;
    }

    function getMyNFTs() external view override returns (TicketStructs.TicketWithNFT[] memory) {
        uint256 balance = balanceOf(msg.sender);
        if (balance == 0) {
            return new TicketStructs.TicketWithNFT[](0);
        }
        
        TicketStructs.TicketWithNFT[] memory myNFTs = new TicketStructs.TicketWithNFT[](balance);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= _tokenIds.current(); i++) {
            if (ownerOf(i) == msg.sender) {
                uint256 eventId = tickets[i].eventId;
                myNFTs[currentIndex] = TicketStructs.TicketWithNFT({
                    tokenId: i,
                    eventId: eventId,
                    eventName: events[eventId].name,
                    ticketType: tickets[i].ticketType,
                    tokenURI: tokenURI(i)
                });
                currentIndex++;
            }
        }
        
        return myNFTs;
    }

    function isEventExpired(uint256 eventId) external view override returns (bool) {
        if (eventId > _eventIds.current()) revert EventNotExist();
        return block.timestamp > uint256(events[eventId].date);
    }

    function getMyPurchaseHistory() external view override returns (TicketStructs.PurchaseHistory[] memory) {
        uint256 totalSupply = _tokenIds.current();
        uint256 purchaseCount = 0;
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].purchaser == msg.sender || ownerOf(i) == msg.sender) {
                purchaseCount++;
            }
        }
        
        if (purchaseCount == 0) {
            return new TicketStructs.PurchaseHistory[](0);
        }
        
        TicketStructs.PurchaseHistory[] memory history = new TicketStructs.PurchaseHistory[](purchaseCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].purchaser == msg.sender || ownerOf(i) == msg.sender) {
                uint256 eventId = tickets[i].eventId;
                
                string memory code = "";
                if ((ownerOf(i) == msg.sender || tickets[i].purchaser == msg.sender) && tickets[i].isUsed) {
                    code = ticketCodes[i];
                }
                
                history[currentIndex] = TicketStructs.PurchaseHistory({
                    tokenId: i,
                    eventId: eventId,
                    eventName: events[eventId].name,
                    eventDate: uint256(events[eventId].date),
                    isExpired: block.timestamp > uint256(events[eventId].date),
                    isUsed: tickets[i].isUsed,
                    ticketType: tickets[i].ticketType,
                    ticketCode: code,
                    tokenURI: tokenURI(i)
                });
                currentIndex++;
            }
        }
        
        return history;
    }
}