// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILoanEth.sol";
import "./ILoaner.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ethLoan is ILoanEth, ERC721{

    event Testing(uint256 line);

    ILoaner private _ethPool;
    IERC20 private _usdc;

    //loan id -> amount of deposited eth for a loan
    mapping(uint256 => uint256) private _depositedETH;
    //loan id -> locktime for a loan 
    mapping(uint256 => uint256) private _unlockTime;
    //loan id -> the sfxsEth backing ration for a loan
    mapping(uint256 => uint256) private _sfxsEthRatioAtOpening;
    //loan id -> amount of usdc borrowed for a loan
    mapping(uint256 => uint256) private _borrowedUSDC;
    //loan id -> liquidation ratio for a loan
    mapping(uint256 => uint256) private _maxLiquiadtionRatio;
    //loan id -> closing fee for the given loan
    mapping(uint256 => uint256) private _closingFee;
    //loan id -> liquidation penalty for a given loan 
    mapping(uint256 => uint256) private _liquidationPenalty;

    function idColateralBalance(uint256 loanId_) external view returns(uint256 amount){
        require(ownerOf(loanId_)!=address(0));
        return _depositedETH[loanId_];
    }

    uint256 private _count;
    uint256 private _currLockTime;
    uint256 public _currMaxLiquidationRatio;
    uint256 public _currClosingFee;
    uint256 public _currLiquidationPenalty;

    //eventually change constructor to use the passed in maxiquidationRatio, closingFee, and liquiationPenalty
    //constructor(address ethPool_, address usdc_, uint256 maxLiquidationRatio_, uint256 closingFee_, uint256 liquiationPenalty_) ERC721("Fetti Eth Colateralized Loan", "FetEthUsdc") {
    constructor(address ethPool_, address usdc_) ERC721("Fetti Eth Colateralized Loan", "FetEthUsdc") {
        _ethPool = ILoaner(ethPool_);
        _usdc = IERC20(usdc_);
        _currLockTime = 1;
        _currMaxLiquidationRatio = 80;
        _currClosingFee = 1;
        _currLiquidationPenalty=15;
        _count = 0;
    }

    //eth doesn't have an address
    function suppliedAsset() external pure returns(address){
        return address(0);
    }

    function borrowedAsset() external view returns(address){
        return address(_usdc);
    }

    //not needed for eth
    function depositColateral(address receiver_, uint256 amount_) external pure returns(uint256 loanId){
        require(0==1, "This is an eth loan");
        return 0;
    }

    //not needed for eth
    function addColateral(uint256 loanId_, uint256 amount) external pure returns(uint256 totalColateral){
        require(0==1, "This is an eth loan");
        return 0;
    }

    //not needed for eth
    function widthdrawColateral(address receiver_, uint256 loanId_) external pure returns(uint256){
        require(0==1, "This is an eth loan");
        return 0;
    }

    //mapping(uint256 => uint256) public _depositedETH;
    //mapping(uint256 => uint256) public _sfxsEthRatioAtOpening;
    //mapping(uint256 => uint256) public _borrowedUSDC;
    //mapping(uint256 => uint256) public _maxLiquiadtionRatio;
    //mapping(uint256 => uint256) public _closingFee;
    //mapping(uint256 => uint256) public _liquidationPenalty;

    function depositColateralEth() external payable returns(uint256){
        require(balanceOf(msg.sender)==0, "Cannot have more than 1 outstanding loan");
        _count=_count+1;
        _unlockTime[_count] = block.timestamp + _currLockTime;
        _depositedETH[_count] = msg.value;
        _maxLiquiadtionRatio[_count] = _currMaxLiquidationRatio;
        _closingFee[_count] = _currClosingFee;
        _mint(msg.sender, _count);
        return _count;
    }

    function addColateralEth(uint256 loanId_) external payable returns(uint256){      
        require(ownerOf(loanId_)!=address(0));
        _depositedETH[loanId_]+=msg.value;
        return _depositedETH[loanId_];
    }

    //use the other stored loan info to take fees from the closure
    //remove loan information from mapping
    function widthdrawColateralEth(address payable receiver_, uint256 loanId_) external payable returns(uint256){
        require(msg.sender==ownerOf(loanId_));
        require(block.timestamp>_unlockTime[loanId_]);
        uint256 amount = _depositedETH[loanId_];
        _burn(loanId_);
        receiver_.transfer(amount);
        return amount;
    }

    function totalColateral(uint256 loanId_) public view returns(uint256 amount){
        require(ownerOf(loanId_)!=address(0));
        return _depositedETH[loanId_];
    }

    function borrow(uint256 loanId_, uint256 amount_, address sendTo_) external pure returns(uint256 amount){
        return 0;
    }

    function maxBorrow(uint256 loanId_, address sendTo_) external pure returns(uint256 amount){
        return 0;
    }

    function liquidityRatio(uint256 loanId_) external pure returns(uint256 amount){
        return 0;
    }

    function poke(address sendRewards_) external pure returns(uint256 amount){
        return 0;
    }
}