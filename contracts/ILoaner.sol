pragma solidity ^0.8.0;

interface ILoaner{

    function totalFreeUSDC() external returns(uint256 amount);

    function totalLoanedUSDC() external returns(uint256 amount);

    function closeableLoanCount() external returns(uint256 amount);

    function sendUsdcToLoan(address loan_) external returns(uint256 amount);

    function approvePoolLoan(uint256 amount) external returns(uint256 totalUSDCAvailble);
}