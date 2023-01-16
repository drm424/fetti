// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHolding.sol";
import "./IVault.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Holding{

    address private _gov;
    IVault private _vault;
    IERC20 private _usdc;

    constructor(address vault_, address usdc_){
        _gov = msg.sender;
        _vault = IVault(vault_);
        _usdc = IERC20(usdc_);
    }

    function totalAssets() public view returns(uint256 assets){
        return _usdc.balanceOf(address(this));
    }

    function widthdraw(uint256 assets) external{
        require(msg.sender==address(_vault));
        require(assets<=totalAssets());
        _usdc.transfer(address(_vault), assets);
    }

    function widthdrawAll() external{
        require(msg.sender==address(_vault));
        _usdc.transfer(address(_vault), totalAssets());
    }
}