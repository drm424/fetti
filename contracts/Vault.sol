// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC4626.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./FettiERC20.sol";
import "./IVault.sol";
import "./ILoaner.sol";


contract Vault is IVault{

    IERC20 private _dai;
    IERC4626 private _share;
    ILoaner private _loaner;
    address private _gov;    

    constructor(address dai_, address share_, address loaner_){
        _dai = IERC20(dai_);
        _share = IERC4626(share_);
        _loaner = ILoaner(loaner_);
        _gov = msg.sender;
    }

    function sendDaiToLoaner(uint256 amount_) external returns(uint256 amount){
        require(msg.sender==_gov,"only ogv!!!");
        require(totalDaiInVault()>amount_,"Don't have enough usdc in vault!");
        SafeERC20.safeTransfer(_dai, address(_loaner), amount_);
        return 0;
    }

    //total usdc in vault & loaned out 
    //calls loaner total usdc that adds loaned out and usdc held
    function totalDai() external view returns(uint256 amount){
        return _dai.balanceOf(address(this)) + _loaner.totalDai();
    }

    function totalDaiInVault() public view returns(uint256 assets){
        return _dai.balanceOf(address(this));
    }

    //function widthdraw to send tokens 
    //require the caller to be the share address
    function widthdraw(address receiver, uint256 assets) external override{
        require(msg.sender==address(_share), "Must be the share token!!!");
        SafeERC20.safeTransfer(_dai, receiver, assets);
    }
}