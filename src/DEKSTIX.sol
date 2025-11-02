// SPDX-License-Identifier: MIT
pragma solidity ^0.8.20;

import "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract DEKSTIX is ERC20 {
    constructor() ERC20("DEKSTIX", "DEKSTIX") {
        _mint(msg.sender, 1000000 * 10**decimals());
    }

    function mint(address to, uint256 amount) public {
        _mint(to, amount);
    }

    function mintToSelf(uint256 amount) public {
        _mint(msg.sender, amount);
    }
}