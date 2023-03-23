// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface TWAPPriceGetter {
    function tokenPriceDai() external view returns (uint price);
}