// // SPDX-License-Identifier: MIT
// pragma solidity ^0.8.0;

// import "forge-std/Test.sol";
// import "../src/EventTicketingNFT.sol";
// import "../src/interfaces/ITicketTypes.sol";

// contract EventTicketingNFTTest is Test {
//     EventTicketingNFT public nft;
//     address public owner;
//     address public buyer;
//     uint256 public eventId;
//     uint256 public tokenId;

//     function setUp() public {
//         // Setup owner and buyer addresses
//         owner = makeAddr("owner");
//         buyer = makeAddr("buyer");
        
//         // Deploy contract with owner
//         vm.prank(owner);
//         nft = new EventTicketingNFT(owner);
        
//         // Create event
//         vm.prank(owner);
//         eventId = nft.createEvent(
//             "Test Event",
//             "Test Description",
//             "Test Location",
//             "ipfs://test-image",
//             block.timestamp + 1 days,
//             block.timestamp + 2 days,
//             block.timestamp + 3 days,
//             100 // total tickets
//         );

//         // Mint a ticket as owner
//         vm.prank(owner);
//         tokenId = nft.mintTicket(eventId, ITicketTypes.TicketType.STANDARD, "ipfs://test-token");
//     }

//     function testBuyAndUseTicket() public {
//         // Set ticket price
//         vm.prank(owner);
//         nft.setTicketPrice(eventId, ITicketTypes.TicketType.STANDARD, 0.1 ether);

//         // Buy ticket as buyer
//         vm.deal(buyer, 1 ether); // Give buyer some ETH
//         vm.prank(buyer);
//         nft.buyTicket{value: 0.1 ether}(tokenId);

//         // Verify buyer is now owner of the ticket
//         assertEq(nft.ownerOf(tokenId), buyer, "Buyer should be the owner after purchase");

//         // Use ticket as buyer
//         vm.prank(buyer);
//         nft.useTicket(tokenId);

//         // Verify ticket is used
//         assertTrue(nft.isTicketUsed(tokenId), "Ticket should be marked as used");

//         // Get ticket details
//         (
//             bool isCurrentOwner,
//             bool isPurchaser,
//             bool isUsed,
//             address currentOwner,
//             address ticketPurchaser
//         ) = nft.checkTicketAccess(tokenId);

//         // Verify all ticket details
//         assertTrue(isUsed, "Ticket should be used");
//         assertEq(currentOwner, buyer, "Current owner should be buyer");
//         assertEq(ticketPurchaser, buyer, "Ticket purchaser should be buyer");

//         // Try to get ticket code as buyer
//         vm.prank(buyer);
//         string memory code = nft.getTicketCode(tokenId);
//         assertTrue(bytes(code).length > 0, "Ticket code should not be empty");
//     }

//     function testCannotGetCodeBeforeUse() public {
//         // Buy ticket
//         vm.deal(buyer, 1 ether);
//         vm.prank(buyer);
//         nft.buyTicket{value: 0.1 ether}(tokenId);

//         // Try to get code before using ticket (should fail)
//         vm.prank(buyer);
//         vm.expectRevert("Ticket not used yet");
//         nft.getTicketCode(tokenId);
//     }

//     function testOnlyOwnerOrPurchaserCanGetCode() public {
//         // Buy and use ticket
//         vm.deal(buyer, 1 ether);
//         vm.prank(buyer);
//         nft.buyTicket{value: 0.1 ether}(tokenId);

//         vm.prank(buyer);
//         nft.useTicket(tokenId);

//         // Try to get code with random address (should fail)
//         address randomUser = makeAddr("random");
//         vm.prank(randomUser);
//         vm.expectRevert();
//         nft.getTicketCode(tokenId);

//         // Original buyer should be able to get code
//         vm.prank(buyer);
//         string memory code = nft.getTicketCode(tokenId);
//         assertTrue(bytes(code).length > 0, "Buyer should be able to get code");
//     }

//     function testTransferAndCodeAccess() public {
//         // Buy and use ticket
//         vm.deal(buyer, 1 ether);
//         vm.prank(buyer);
//         nft.buyTicket{value: 0.1 ether}(tokenId);

//         vm.prank(buyer);
//         nft.useTicket(tokenId);

//         // Transfer to new owner
//         address newOwner = makeAddr("newOwner");
//         vm.prank(buyer);
//         nft.transferFrom(buyer, newOwner, tokenId);

//         // Both new owner and original purchaser should be able to get code
//         vm.prank(newOwner);
//         string memory codeFromNewOwner = nft.getTicketCode(tokenId);
//         console.log("codeFromNewOwner", codeFromNewOwner);
//         assertTrue(bytes(codeFromNewOwner).length > 0, "New owner should be able to get code");

//         vm.prank(buyer);
//         string memory codeFromBuyer = nft.getTicketCode(tokenId);
//         assertTrue(bytes(codeFromBuyer).length > 0, "Original buyer should still be able to get code");

//         // Verify codes are the same
//         assertEq(codeFromNewOwner, codeFromBuyer, "Codes should be identical");
//     }

//     receive() external payable {}
// } 