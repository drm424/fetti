// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILoanEth.sol";
import "./ILoaner.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ethLoan is ILoanEth, ERC721{

    ILoaner private _ethPool;
    IERC20 private _usdc;

    //loan id -> amount of deposited eth for a loan
    mapping(uint256 => uint256) public _depositedETH;
    //loan id -> the sfxsEth backing ration for a loan
    mapping(uint256 => uint256) public _sfxsEthRatioAtOpening;
    //loan id -> amount of usdc borrowed for a loan
    mapping(uint256 => uint256) public _borrowedUSDC;
    //loan id -> liquidation ratio for a loan
    mapping(uint256 => uint256) public _maxLiquiadtionRatio;
    //loan id -> closing fee for the given loan
    mapping(uint256 => uint256) public _closingFee;
    //loan id -> liquidation penalty for a given loan 
    mapping(uint256 => uint256) public _liquidationPenalty;

    uint256 private _count;
    uint256 public _currMaxLiquidationRatio;
    uint256 public _currClosingFee;
    uint256 public _currLiquidationPenalty;

    //eventually change constructor to use the passed in maxiquidationRatio, closingFee, and liquiationPenalty
    constructor(address ethPool_, address usdc_, uint256 maxLiquidationRatio_, uint256 closingFee_, uint256 liquiationPenalty_) ERC721("Fetti Eth Colateralized Loan", "FetEthUsdc") {
        _ethPool = ILoaner(ethPool_);
        _usdc = IERC20(usdc_);
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

    function depositColateral(address receiver_, uint256 amount_) external returns(uint256 loanId){
        require(0==1, "This is an eth loan");
        return 0;
    }

    function addColateral(uint256 loanId_, uint256 amount) external returns(uint256 totalColateral){
        require(0==1, "This is an eth loan");
        return 0;
    }

    function depositColateralEth(address receiver_, uint256 amount_) external payable returns(uint256 loanId){
        return 0;
    }

    function addColateralEth(uint256 loanId_, uint256 amount) external payable returns(uint256 totalColateral){
        return 0;
    }

    function borrow(uint256 loanId_, uint256 amount_, address sendTo_) external returns(uint256 amount){
        return 0;
    }

    function maxBorrow(uint256 loanId_, address sendTo_) external returns(uint256 amount){
        return 0;
    }

    function liquidityRatio(uint256 loanId_) external returns(uint256 amount){
        return 0;
    }

    function poke(address sendRewards_) external returns(uint256 amount){
        return 0;
    }
}