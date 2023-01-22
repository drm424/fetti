pragma solidity ^0.8.0;

interface IPool{

    event AddedUsdcFromVault(uint256 amount);

    event SuppliedColateral(address borrower, uint256 amount);

    event BorrowedUsdc(address borrower, uint256 amount);
    
    function totalFreeUSDC() external returns(uint256);

    function totalLoanedUSDC() external returns(uint256);

    function totalUSDC() external returns(uint256);
}