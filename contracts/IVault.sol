// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault{

    event Deposit(address caller, address receiver, uint256 assets, uint256 shares);

    event Widthdraw(address caller, address receiver, uint256 shares, uint256 assets);

    function totalAssets() external view returns(uint256 assets);

    function widthdraw(address receiver, uint256 assets) external;
}