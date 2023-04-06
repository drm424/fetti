pragma solidity ^0.8.0;

import "./IVault.sol";
import "./ILoaner.sol";
import "./IPool.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Loaner is ILoaner{

    event SentLoan(address borrower, uint256 amount);
    event ChangedMax(uint256 newMax_);

    address private _gov;

    IPool private _pool;
    uint256 private _maxBorrow;

    IERC20 private _dai;
  

    constructor(address dai_){
        _gov = msg.sender;
        _dai = IERC20(dai_);
    }

    //add usdc in loaner and loaned out amount of all pools
    //add usdc loaned out by iterating through the mapping of pools and calling totalLoaned()
    function totalDai() public view returns(uint256 amount){
        return totalDaiInLoaner()+totalLoanedOut();
    }

    function totalDaiInLoaner() public view returns(uint256 assets){
        return _dai.balanceOf(address(this));
    }

    //iterate through pools and add total loans outstanding
    function totalLoanedOut() public view returns(uint256 amount){
        return _pool.totalLoanedOut();
    }
    
    function addPool(address newPool_, uint256 maxBorrow_) external {
        require(msg.sender==_gov,"Only gov!!!");
        _pool=  IPool(newPool_);
        _maxBorrow = maxBorrow_;
    }
    
    function setPoolMax(uint256 newMax_) external {
        require(msg.sender==_gov,"Only gov!!!");
        _maxBorrow = newMax_;
        emit ChangedMax(newMax_);
    }

    function getPoolMax(uint256 poolId_) external view returns(uint256 max){
        return _maxBorrow;
    }

    //not sure what happens if pool doesn't exist
    function sendLoan(address payable borrower_, uint256 amount_) external returns(uint256){
        require(msg.sender==address(_pool),"must be the pool!!");
        require(poolFreeDai()>=amount_, "would go over pool loan limit");
        require(totalDaiInLoaner()>=amount_,"Don't have enough usdc in loaner!");
        SafeERC20.safeTransfer(_dai, borrower_, amount_);
        emit SentLoan(borrower_, amount_);
        return amount_;
    }

    function poolFreeDai() public view returns(uint256){
        if(_maxBorrow>totalDaiInLoaner()){
            return totalDaiInLoaner();
        }
        return _maxBorrow-_pool.totalLoanedOut();
    }

    function getPoolLoanAmount() public view returns(uint256){
        return _pool.totalLoanedOut();
    }
}