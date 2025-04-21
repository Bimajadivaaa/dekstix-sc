// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "@openzeppelin/contracts/token/ERC721/extensions/ERC721URIStorage.sol";
import "@openzeppelin/contracts/access/Ownable.sol";
import "@openzeppelin/contracts/utils/Counters.sol";
import "@openzeppelin/contracts/utils/Strings.sol";

contract EventTicketingNFT is ERC721URIStorage, Ownable {
    using Counters for Counters.Counter;
    using Strings for uint256;
    
    Counters.Counter private _eventIds;
    Counters.Counter private _tokenIds;
    Counters.Counter private _codeIds;

    enum TicketType { STANDARD, PREMIUM, VIP }

    struct Event {
        string name;
        string description;
        string location;
        string imageURI;
        uint256 date;
        uint256 startTime;
        uint256 endTime;
        bool isActive;
        uint256 remainingTickets;
        mapping(uint8 => uint256) ticketPrices;
    }

    struct Ticket {
        uint256 eventId;
        TicketType ticketType;
        bool isListed;
        bool isUsed;
        bytes32 uniqueCodeHash;
    }

    struct CodeStatus {
        bool isValid;
        bool isUsed;
        uint256 tokenId;
        address owner;
    }

    // Base URI untuk metadata
    string private _baseTokenURI;

    // Mapping dari eventId ke struct Event
    mapping(uint256 => Event) private events;
    
    // Mapping dari tokenId ke informasi tiket
    mapping(uint256 => Ticket) public tickets;
    
    // Mapping dari code hash ke status kode
    mapping(bytes32 => CodeStatus) private codes;
    
    // Mapping dari tokenId ke kode tiket
    mapping(uint256 => string) private ticketCodes;
    
    // Events
    event EventCreated(uint256 indexed eventId, string name, uint256 date);
    event TicketPriceSet(uint256 indexed eventId, TicketType ticketType, uint256 price);
    event TicketMinted(uint256 indexed tokenId, uint256 indexed eventId, address indexed owner, TicketType ticketType);
    event TicketPurchased(uint256 indexed tokenId, uint256 indexed eventId, address indexed buyer, uint256 price);
    event TicketUsed(uint256 indexed tokenId, uint256 indexed eventId);
    event CodeVerified(uint256 indexed tokenId, uint256 indexed eventId, bool isValid, bool isUsed);

    constructor(address initialOwner) 
        ERC721("Event Ticket", "TCKT")
        Ownable(initialOwner)
    {}
    
    function setBaseURI(string memory baseURI) public onlyOwner {
        _baseTokenURI = baseURI;
    }
    
    function _baseURI() internal view override returns (string memory) {
        return _baseTokenURI;
    }

    // Fungsi untuk membuat event baru
    function createEvent(
        string memory name,
        string memory description,
        string memory location,
        string memory imageURI,
        uint256 date,
        uint256 startTime,
        uint256 endTime,
        uint256 totalTickets
    ) public onlyOwner returns (uint256) {
        _eventIds.increment();
        uint256 newEventId = _eventIds.current();
        
        Event storage newEvent = events[newEventId];
        newEvent.name = name;
        newEvent.description = description;
        newEvent.location = location;
        newEvent.imageURI = imageURI;
        newEvent.date = date;
        newEvent.startTime = startTime;
        newEvent.endTime = endTime;
        newEvent.isActive = true;
        newEvent.remainingTickets = totalTickets;
        
        // Set harga default untuk semua tipe tiket (dalam wei)
        newEvent.ticketPrices[uint8(TicketType.STANDARD)] = 0.1 ether;
        newEvent.ticketPrices[uint8(TicketType.PREMIUM)] = 0.2 ether;
        newEvent.ticketPrices[uint8(TicketType.VIP)] = 1 ether;
        
        emit EventCreated(newEventId, name, date);
        return newEventId;
    }
    
    // Fungsi untuk mengatur harga tiket berdasarkan tipe
    function setTicketPrice(uint256 eventId, TicketType ticketType, uint256 price) public onlyOwner {
        require(eventId <= _eventIds.current(), "Event does not exist");
        require(events[eventId].isActive, "Event is not active");
        
        events[eventId].ticketPrices[uint8(ticketType)] = price;
        
        emit TicketPriceSet(eventId, ticketType, price);
    }
    
    // Fungsi untuk melihat harga tiket berdasarkan tipe
    function getTicketPrice(uint256 eventId, TicketType ticketType) public view returns (uint256) {
        require(eventId <= _eventIds.current(), "Event does not exist");
        return events[eventId].ticketPrices[uint8(ticketType)];
    }

    // Fungsi untuk melihat informasi event
    function getEventInfo(uint256 eventId) public view returns (
        string memory name,
        string memory description,
        string memory location,
        string memory imageURI,
        uint256 date,
        uint256 startTime,
        uint256 endTime,
        bool isActive,
        uint256 remainingTickets
    ) {
        require(eventId <= _eventIds.current(), "Event does not exist");
        Event storage eventInfo = events[eventId];
        
        return (
            eventInfo.name,
            eventInfo.description,
            eventInfo.location,
            eventInfo.imageURI,
            eventInfo.date,
            eventInfo.startTime,
            eventInfo.endTime,
            eventInfo.isActive,
            eventInfo.remainingTickets
        );
    }
    
    // Fungsi untuk mengaktifkan/menonaktifkan event
    function toggleEventStatus(uint256 eventId) public onlyOwner {
        require(eventId <= _eventIds.current(), "Event does not exist");
        events[eventId].isActive = !events[eventId].isActive;
    }
    
    // Fungsi untuk membuat kode unik tiket
    function generateUniqueCode(uint256 tokenId, uint256 eventId) private returns (string memory) {
        _codeIds.increment();
        uint256 timestamp = block.timestamp;
        uint256 random = uint256(keccak256(abi.encodePacked(
            tokenId,
            eventId,
            timestamp,
            msg.sender,
            _codeIds.current()
        )));
        
        return string(abi.encodePacked(
            "EVT",
            eventId.toString(),
            "-TKT",
            tokenId.toString(),
            "-",
            uint256(random % 1000000).toString()
        ));
    }

    // Fungsi untuk mencetak tiket oleh owner
    function mintTicket(
        uint256 eventId, 
        TicketType ticketType, 
        string memory tokenURI
    ) public onlyOwner returns (uint256) {
        require(eventId <= _eventIds.current(), "Event does not exist");
        require(events[eventId].isActive, "Event is not active");
        require(events[eventId].remainingTickets > 0, "No tickets remaining");
        
        _tokenIds.increment();
        uint256 newTokenId = _tokenIds.current();

        _safeMint(msg.sender, newTokenId);
        
        // Jika VIP atau tokenURI tidak kosong, set URI kustom
        if (ticketType == TicketType.VIP || bytes(tokenURI).length > 0) {
            _setTokenURI(newTokenId, tokenURI);
        }
        
        tickets[newTokenId] = Ticket({
            eventId: eventId,
            ticketType: ticketType,
            isListed: true,
            isUsed: false,
            uniqueCodeHash: bytes32(0)
        });
        
        // Kurangi jumlah tiket yang tersisa
        events[eventId].remainingTickets--;

        emit TicketMinted(newTokenId, eventId, msg.sender, ticketType);
        return newTokenId;
    }

    // Fungsi untuk membeli tiket
    function buyTicket(uint256 tokenId) public payable {
        require(tokenId <= _tokenIds.current(), "Ticket does not exist");
        require(tickets[tokenId].isListed, "Ticket is not listed for sale");
        require(!tickets[tokenId].isUsed, "Ticket has been used");
        
        uint256 eventId = tickets[tokenId].eventId;
        require(events[eventId].isActive, "Event is not active");
        
        uint256 price = events[eventId].ticketPrices[uint8(tickets[tokenId].ticketType)];
        require(msg.value >= price, "Insufficient payment");

        address payable owner = payable(ownerOf(tokenId));
        owner.transfer(msg.value);

        _transfer(owner, msg.sender, tokenId);
        tickets[tokenId].isListed = false;

        emit TicketPurchased(tokenId, eventId, msg.sender, msg.value);
    }

    // Fungsi untuk melihat semua tiket yang tersedia untuk dijual
    function getListedTickets(uint256 eventId) public view returns (uint256[] memory) {
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

    // Fungsi untuk menggunakan tiket dan mendapatkan kode unik
    function useTicket(uint256 tokenId) public {
        require(ownerOf(tokenId) == msg.sender, "Not the ticket owner");
        require(!tickets[tokenId].isUsed, "Ticket already used");
        
        uint256 eventId = tickets[tokenId].eventId;
        require(events[eventId].isActive, "Event is not active");

        string memory uniqueCode = generateUniqueCode(tokenId, eventId);
        bytes32 codeHash = keccak256(abi.encodePacked(uniqueCode));
        
        tickets[tokenId].uniqueCodeHash = codeHash;
        tickets[tokenId].isUsed = true;
        
        ticketCodes[tokenId] = uniqueCode;
        
        codes[codeHash] = CodeStatus({
            isValid: true,
            isUsed: false,
            tokenId: tokenId,
            owner: msg.sender
        });

        emit TicketUsed(tokenId, eventId);
    }

    // Fungsi untuk memverifikasi kode tiket (oleh penyelenggara event/owner)
    function verifyCode(string memory code) public onlyOwner returns (bool) {
        bytes32 codeHash = keccak256(abi.encodePacked(code));
        CodeStatus memory status = codes[codeHash];
        
        require(status.isValid, "Invalid code");
        require(!status.isUsed, "Code has been used");
        
        uint256 tokenId = status.tokenId;
        uint256 eventId = tickets[tokenId].eventId;

        codes[codeHash].isUsed = true;
        
        emit CodeVerified(tokenId, eventId, true, true);
        return true;
    }

    // Fungsi untuk mendapatkan kode tiket (hanya oleh pemilik tiket)
    function getTicketCode(uint256 tokenId) public view returns (string memory) {
        require(ownerOf(tokenId) == msg.sender, "Only ticket owner can view code");
        require(tickets[tokenId].isUsed, "Ticket not used yet");
        return ticketCodes[tokenId];
    }

    // Fungsi untuk memeriksa apakah tiket sudah digunakan
    function isTicketUsed(uint256 tokenId) public view returns (bool) {
        return tickets[tokenId].isUsed;
    }
    
    // Fungsi untuk mendapatkan tipe tiket
    function getTicketType(uint256 tokenId) public view returns (TicketType) {
        return tickets[tokenId].ticketType;
    }
    
    // Fungsi untuk mendapatkan semua tiket berdasarkan tipe dan event
    function getTicketsByTypeAndEvent(uint256 eventId, TicketType ticketType) public view returns (uint256[] memory) {
        uint256 totalSupply = _tokenIds.current();
        uint256 typeCount = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].eventId == eventId && tickets[i].ticketType == ticketType) {
                typeCount++;
            }
        }

        uint256[] memory filteredTickets = new uint256[](typeCount);
        uint256 currentIndex = 0;

        for (uint256 i = 1; i <= totalSupply; i++) {
            if (tickets[i].eventId == eventId && tickets[i].ticketType == ticketType) {
                filteredTickets[currentIndex] = i;
                currentIndex++;
            }
        }

        return filteredTickets;
    }
    
    // Fungsi untuk mendapatkan semua event
    function getAllEvents() public view returns (uint256[] memory) {
        uint256 eventCount = _eventIds.current();
        uint256[] memory allEvents = new uint256[](eventCount);
        
        for (uint256 i = 1; i <= eventCount; i++) {
            allEvents[i-1] = i;
        }
        
        return allEvents;
    }
    
    // Fungsi untuk mendapatkan semua event aktif
    function getActiveEvents() public view returns (uint256[] memory) {
        uint256 eventCount = _eventIds.current();
        uint256 activeCount = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeCount++;
            }
        }
        
        uint256[] memory activeEvents = new uint256[](activeCount);
        uint256 currentIndex = 0;
        
        for (uint256 i = 1; i <= eventCount; i++) {
            if (events[i].isActive) {
                activeEvents[currentIndex] = i;
                currentIndex++;
            }
        }
        
        return activeEvents;
    }
}