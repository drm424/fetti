// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract gns is ERC20{

    constructor() ERC20("gns", "gns"){
        _mint(msg.sender, 10**19);
    }

    function decimals() public pure override returns (uint8) {
        return 18;
    }
}