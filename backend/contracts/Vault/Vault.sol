// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/@openzeppelin/contracts/interfaces/IERC4626.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "../Token/Token.sol";
import "./IVault.sol";
import "../Holding/IHolding.sol";


contract Vault is IVault{

    IERC20 private immutable _usdc;
    IERC4626 private immutable _share;
    address private immutable _gov;

    mapping(uint256=>IHolding) private _holdings;

    //figure out how to do without casting
    constructor(address usdc_, address share_){
        _usdc = IERC20(usdc_);
        _share = IERC4626(share_);
        _gov = msg.sender;
    }

    function totalAssets() external view override returns(uint256 assets){
        return _usdc.balanceOf(address(this));
    }

    //function widthdraw to send tokens 
    //require the caller to be the share address
    function widthdraw(address receiver, uint256 assets) external override{
        require(msg.sender==address(_share), "Must be the share token!!!");
        SafeERC20.safeTransfer(_usdc, receiver, assets);
    }

}