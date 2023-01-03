// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IVault{

    event Deposit(address caller, address receiver, uint256 assets, uint256 shares);

    event Widthdraw(address caller, address receiver, uint256 shares, uint256 assets);

    //total assets calls the oracle proxy to get the totalAssets held
    //current index is in the token contract
    function totalAssets() external view returns(uint256 assets);

    function widthdraw(address receiver, uint256 assets) external;

    //function deposit() external returns(uint256 shares);

    //function mint(uint256 shares, address receiver) external returns (uint256 assets);

    //function redeem(uint256 shares, address receiver, address owner) external returns (uint256 assets);
}