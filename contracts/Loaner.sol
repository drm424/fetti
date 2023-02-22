pragma solidity ^0.8.0;

import "./IVault.sol";
import "./ILoaner.sol";
import "./IPool.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";


contract Loaner is ILoaner{

    event SentLoan(uint256 poolId, address borrower, uint256 amount);

    address private _gov;

    struct Pool{
        IPool _pool;
        uint256 _poolId;
        uint256 _maximumBorrow;
    }

    IERC20 private _usdc;
    uint256[] private _poolIds;
    mapping(uint256=>Pool) private _pools;

    constructor(address usdc_){
        _gov = msg.sender;
        _usdc = IERC20(usdc_);
    }

    //add usdc in loaner and loaned out amount of all pools
    //add usdc loaned out by iterating through the mapping of pools and calling totalLoaned()
    function totalUsdc() public view returns(uint256 amount){
        return _usdc.balanceOf(address(this));
    }
    
    function addPool(address newPool_, uint256 poolId_, uint256 maxBorrow_) external returns(uint256 poolId){
        require(msg.sender==_gov,"Only gov!!!");
        _pools[poolId_] = Pool(IPool(newPool_),poolId_,maxBorrow_);
        _poolIds.push(poolId_);
        return poolId_;
    }
    
    function setPoolMax(uint256 poolId_, uint256 newMax_) external returns(uint256 maximum){
        require(msg.sender==_gov,"Only gov!!!");
        _pools[poolId_]._maximumBorrow = newMax_;
        return _pools[poolId_]._maximumBorrow;
    }

    function getPoolMax(uint256 poolId_) external view returns(uint256 max){
        return _pools[poolId_]._maximumBorrow;
    }

    //not sure what happens if pool doesn't exist
    function sendLoan(address payable borrower_, uint256 poolId_, uint256 amount_) external returns(uint256 amount){
        require(_pools[poolId_]._poolId!=0,"must exist");
        require(msg.sender==address(_pools[poolId_]._pool),"must be the pool!!");
        require(totalUsdcInLoaner()>=amount_,"Don't have enough usdc in loaner!");
        SafeERC20.safeTransfer(_usdc, borrower_, amount_);
        emit SentLoan(poolId_, borrower_, amount_);
        return amount_;
    }

    function totalUsdcInLoaner() public view returns(uint256 assets){
        return _usdc.balanceOf(address(this));
    }

    function poolFreeUsdc(uint256 poolId_) public returns(uint256){
        require(_pools[poolId_]._poolId!=0,"must exist");
        return _pools[poolId_]._maximumBorrow-_pools[poolId_]._pool.totalLoanedOut();

    }

    //iterate through pools and add total loans outstanding
    function totalLoanedOut() external returns(uint256 amount){
        return 0;
    }
}