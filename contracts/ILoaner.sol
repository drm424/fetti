pragma solidity ^0.8.0;

interface ILoaner{

    function totalDai() external view returns(uint256 amount);
    
    function addPool(address newPool_, uint256 maxBorrow_) external;
    
    function setPoolMax(uint256 newMax_) external;

    function sendLoan(address payable borrower_, uint256 amount_) external returns(uint256);

    function totalLoanedOut() external returns(uint256 amount);

    function poolFreeDai() external returns(uint256);

    function sendToVault(uint256 amount_) external returns(uint256);
}