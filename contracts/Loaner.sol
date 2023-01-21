pragma solidity ^0.8.0;

import "./IVault.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loaner{

    address private _gov;
    IVault private _vault;
    IERC20 private _usdc;

    //change addresses to IPool when those are completed
    uint256[] private poolIds;
    mapping(uint256=>address) pools;
    mapping(address=>address) poolAssets;







}