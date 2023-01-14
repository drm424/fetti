pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract USDC is ERC20{

    constructor() ERC20("USDC", "USDC"){
        _mint(msg.sender, 10**7);
    }

    function decimals() public pure override returns (uint8) {
        return 6;
    }
}

