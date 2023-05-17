// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool{
    
    function totalLoanedOut() external view returns(uint256 amount);

    function depositColateral(address receiver_, uint256 amount_) external returns(uint256);

    function addColateral(uint256 loanId_, uint256 amount) external returns(uint256);

    function widthdrawColateral(address receiver_, uint256 loanId_) external returns(uint256);

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256);

    function repayLoan(uint256 loanId_, uint256 amount_) external returns(uint256);

    function liquidate(uint256 loanId_,uint256 amount_,address payer_ ) external; 
}