// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILoan.sol";

interface ILoanEth is ILoan{

    function depositColateralEth(address receiver_, uint256 amount_) external payable returns(uint256 loanId);

    function addColateralEth(uint256 loanId_, uint256 amount) external payable returns(uint256 totalColateral);
}