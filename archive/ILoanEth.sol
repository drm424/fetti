//Deprecated

// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

//import "./IPool.sol";

interface ILoanEth{

    function depositColateralEth() external payable returns(uint256 loanId);

    function addColateralEth(uint256 loanId_) external payable returns(uint256 totalColateral);

    function widthdrawColateralEth(address payable receiver_, uint256 loanId_) external payable returns(uint256);
}