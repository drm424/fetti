// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHolding{

    event Deposit(address sender, uint256 amount);

    event Widthdraw(address receiver, uint256 amount);

    function totalAssets() external returns(uint256 amount);
    
    function initialize() external returns(uint256 amount);

    function fullyLiquid() external returns(bool liquidity);
    
    function deposit(uint256 amount) external returns(uint256 deposit);

    function maxWidthdraw() external returns(uint256 amount);

    function widthdraw(uint256 amount) external returns(uint256 widthdraw);

    //send portion of usdc to vault
    function sendUsdcToVault(uint256 amount) external returns(uint256 amountSent);

    //sells all tokens for usdc, swaps pool token for usdc, sends everything to vault
    function liquidate() external returns(uint256 amount);

    function collectAndReinvestable() external returns(bool reinvestable);

    function collectAndReinvest() external returns(uint256 amount);

}