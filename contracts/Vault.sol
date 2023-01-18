// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/interfaces/IERC4626.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import "./Token.sol";
import "./IVault.sol";
import "./IHolding.sol";


contract Vault is IVault{

    IERC20 private immutable _usdc;
    IERC4626 private immutable _share;
    address private immutable _gov;

    uint256[] holdingIds;
    mapping(uint256=>IHolding) holdings;
    

    constructor(address usdc_, address share_){
        _usdc = IERC20(usdc_);
        _share = IERC4626(share_);
        _gov = msg.sender;
    }

    function totalAssets() external view override returns(uint256 assets){
        uint256 totAssets = 0;
        for(uint256 i = 0;i<holdingIds.length;i++){
            totAssets += holdings[holdingIds[i]].totalAssets();
        }
        return _usdc.balanceOf(address(this)) + totAssets;
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

    function addHolding(uint256 key_, address holding_) external returns(uint256 id){
        require(msg.sender==_gov, "Must be gov!!");
        if(address(holdings[key_])!=address(0)){
            return 0;
        }
        holdings[key_] = IHolding(holding_);
        holdingIds.push(key_);
        return key_;
    }

    function addToHolding(uint256 amount_, uint256 id_) external returns(uint256 amount){
        require(msg.sender==_gov, "Must be gov!!");
        uint256 usdcBal = _usdc.balanceOf(address(this));
        if(amount_>usdcBal){
            return amount_ = _usdc.balanceOf(address(this));
        }
        _usdc.transfer(address(holdings[id_]), amount_);
        return amount;
    }

    function removeFromHolding(uint256 amount_, uint256 id_) external returns(uint256 amount){
        require(msg.sender==_gov);
        uint256 holdingBal = holdings[id_].totalAssets();
        if(amount_> holdingBal){
            amount_ = holdingBal;
        }
        //approve transfer before running this function
        holdings[id_].widthdraw(amount_);
        return amount;
    }

    function getHoldingAddress(uint256 id_) external view returns(address holding){
        return address(holdings[id_]);
    }
}