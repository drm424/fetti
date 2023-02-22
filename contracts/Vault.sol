// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC4626.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./FettiERC20.sol";
import "./IVault.sol";
import "./ILoaner.sol";


contract Vault is IVault{

    IERC20 private _usdc;
    IERC4626 private _share;
    ILoaner private _loaner;
    address private _gov;    

    constructor(address usdc_, address share_, address loaner_){
        _usdc = IERC20(usdc_);
        _share = IERC4626(share_);
        _loaner = ILoaner(loaner_);
        _gov = msg.sender;
    }

    function sendUsdcToLoaner(uint256 amount_) external returns(uint256 amount){
        require(msg.sender==_gov,"only ogv!!!");
        require(totalUsdcInVault()>amount_,"Don't have enough usdc in vault!");
        SafeERC20.safeTransfer(_usdc, address(_loaner), amount_);
        return 0;
    }

    //total usdc in vault & loaned out 
    //calls loaner total usdc that adds loaned out and usdc held
    function totalUsdc() external view returns(uint256 amount){
        return _usdc.balanceOf(address(this)) + _loaner.totalUsdc();
    }

    function totalUsdcInVault() public view returns(uint256 assets){
        return _usdc.balanceOf(address(this));
    }

    //function widthdraw to send tokens 
    //require the caller to be the share address
    function widthdraw(address receiver, uint256 assets) external override{
        require(msg.sender==address(_share), "Must be the share token!!!");
        SafeERC20.safeTransfer(_usdc, receiver, assets);
    }
}