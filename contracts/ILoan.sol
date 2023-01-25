pragma solidity ^0.8.0;

interface ILoan{
    event ColateralDeposit(address sender, uint256 loanId, uint256 amount);

    event BorrowedUSDC(address receiver, uint256 loanId, uint256 amount, uint256 liquidityRatio);

    event RepaidUSDC(address sender, uint256 loanId, uint256 amount, uint256 liquidityRatio);

    event Liquidation(uint256 loanId, uint256 amount, address poker);

    event ClosedLoan(uint256 amount, uint256 vaultProfit);
    
    function depositColateral(address receiver, uint256 amount_) external payable returns(uint256 loanId);

    function addColateral(uint256 loanID, uint256 amount) external returns(uint256 totalColateral);

    function borrow(uint256 loanId, uint256 amount_, address sendTo_) external returns(uint256 amount);

    function maxBorrow(uint256 loanId, address sendTo_) external returns(uint256 amount);

    function liquidityRatio(uint256 loanId) external returns(uint256 amount);

    function poke(address sendRewards_) external returns(uint256 amount);
}