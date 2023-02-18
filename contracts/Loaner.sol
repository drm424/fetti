pragma solidity ^0.8.0;

import "./IVault.sol";
import "./ILoaner.sol";
import "./ILoan.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loaner is ILoaner{

    address private _gov;

    struct Pool{
        address _poolAddress;
        uint256 _poolId;
        uint256 _maximumBorrow;
    }

    IERC20 private _usdc;
    uint256[] private _poolIds;
    mapping(uint256=>Pool) private _pools;


    modifier onlyPool{
        uint256 cond = 0;
        for(uint256 i = 0;i<_poolIds.length;i++){
            if(msg.sender==_pools[_poolIds[i]]._poolAddress){
                cond = 1;
                break;
            }
        }
        require(cond!=0,"msg.sender must be a pool");
        _;
    }

    constructor(address usdc_){
        _gov = msg.sender;
        _usdc = IERC20(usdc_);
    }

    //add usdc loaned out by iterating through the mapping of pools and calling totalLoaned()
    function totalUsdc() public view returns(uint256 amount){
        return _usdc.balanceOf(address(this));
    }
    
    function addPool(address newPool_, uint256 poolId_, uint256 maxBorrow_) external returns(uint256 poolId){
        require(msg.sender==_gov,"Only gov!!!");
        _pools[poolId_] = Pool(newPool_,poolId_,maxBorrow_);
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

    //get rid of modifier and check if msg.sender == poolId address (may have to check if pool exiss before this)
    function sendLoan(address payable borrower_, uint256 poolId_, uint256 amount_) external onlyPool returns(uint256 amount){
        require((amount_+));
        return 0;
    }

    function totalLoanedOut() external returns(uint256 amount){
        return 0;
    }


}