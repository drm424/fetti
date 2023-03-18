// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IGnsStaker{
    function stakeTokens(uint amount) external;
    function unstakeTokens(uint amount) external;
    function harvest() external;
    function pendingRewardDai() view external returns(uint);
}