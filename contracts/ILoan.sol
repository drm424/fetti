pragma solidity ^0.8.0;

interface ILoan{
    event ColateralDeposit(uint256 amount);

    event BorrowedUSDC(uint256 amount, uint256 liquidityRatio);

    event RepaidUSDC(uint256 amount, uint256 liquidityRatio);

    event Liquidation(uint256 amount, address poker);

    event ClosedLoan(uint256 amount, uint256 vaultProfit);

    function borrowedAsset() external returns(address);

    function suppliedAsset() external returns(address);
    
    function depositColateral(uint256 amount_) external payable returns(uint256 amount);

    function borrow(uint256 amount_, address sendTo_) external returns(uint256 amount);

    function maxBorrow(address sendTo_) external returns(uint256 amount);

    function liquidityRatio() external returns(uint256 amount);

    function poke(address sendRewards_) external returns(uint256 amount);
}