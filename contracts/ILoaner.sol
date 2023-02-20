pragma solidity ^0.8.0;

interface ILoaner{

    function totalUsdc() external view returns(uint256 amount);
    
    function addPool(address newPool_, uint256 poolId_, uint256 maxBorrow_) external returns(uint256 poolId);
    
    function setPoolMax(uint256 poolId_, uint256 newMax_) external returns(uint256 maximum);

    function sendLoan(address payable borrower_, uint256 poolId_, uint256 amount_) external returns(uint256 amount);

    function totalLoanedOut() external returns(uint256 amount);
}