// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IHolding{

    event Deposit(address caller, address receiver, uint256 assets, uint256 shares);

    event Widthdraw(address caller, address receiver, uint256 shares, uint256 assets);

    function totalAssets() external view returns(uint256 assets);

    function widthdraw(uint256 assets) external;

    function widthdrawAll() external;

    //add other functionalties like addToPool(), collectAndReinvest(), etc.
}