// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IHolding.sol";
import "../Vault/IVault.sol";
import "../../node_modules/@openzeppelin/contracts/token/ERC20/ERC20.sol";
import "../../node_modules/@openzeppelin/contracts/interfaces/IERC4626.sol";



contract Holding is IHolding{

    //how would i find this
    //id is max+1 and then figure out how to add through vault gov addy
    uint256 private _vaultId;
    bool private immutable _fullyLiquid;

    uint256 private _assets;

    IVault private _vault;
    IERC20 private _usdc;
    IERC4626 private _share;
    address private _gov;

    address private _projectAddress;

    constructor(address vault_, address usdc_, address share_, address projectAddress_, bool fullyLiquid_){
        _gov = msg.sender;
        _vault = IVault(vault_);
        _usdc = IERC20(usdc_);
        _share = IERC4626(share_);
        _projectAddress = projectAddress_;
        _fullyLiquid = fullyLiquid_;
    }

    function totalAssets() external view override returns(uint256 amount){
        return 0;
    }
    
    function initialize() external override returns(uint256 amount){
        return 0;
    }

    function fullyLiquid() external override returns(bool liquidity){
        return false;
    }
    
    function deposit(uint256 amount) external override returns(uint256 deposit){
        return 0;
    }

    function maxWidthdraw() external override returns(uint256 amount){
        return 0;
    }

    function widthdraw(uint256 amount) external override returns(uint256 widthdraw){
        return 0;
    }

    //send portion of usdc to vault
    function sendUsdcToVault(uint256 amount) external override returns(uint256 amountSent){
        return 0;
    }

    //sells all tokens for usdc, swaps pool token for usdc, sends everything to vault
    function liquidate() external override returns(uint256 amount){
        return 0;
    }

    function collectAndReinvestable() external override returns(bool reinvestable){
        return false;
    }

    function collectAndReinvest() external override returns(uint256 amount){
        return 0;
    }

}