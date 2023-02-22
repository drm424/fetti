// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

interface IPool{
    
    function totalLoanedOut() external view returns(uint256 amount);

    function depositColateral(address receiver_, uint256 amount_) external returns(uint256 loanId);

    function depositColateralEth() external payable returns(uint256 loanId);

    function addColateral(uint256 loanId_, uint256 amount) external returns(uint256 totalColateral);

    function addColateralEth(uint256 loanId_) external payable returns(uint256 totalColateral);

    function totalColateral(uint256 loanId_) external returns(uint256 amount);

    function widthdrawColateral(address receiver_, uint256 loanId_) external returns(uint256);

    function widthdrawColateralEth(address payable receiver_, uint256 loanId_) external payable returns(uint256);

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256 amount);

    function maxBorrow(uint256 loanId_, address sendTo_) external returns(uint256 amount);

    function poke(address sendRewards_) external returns(uint256 amount);
}