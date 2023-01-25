pragma solidity ^0.8.0;

import "./ILoan.sol";
import "./ILoaner.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loan is ILoan, ERC721{

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

    uint256 private count;
    uint256 public _currMaxLiquidationRatio;
    uint256 public _currClosingFee;
    uint256 public _currLiquidationPenalty;

    //eventually change constructor to use the passed in maxiquidationRatio, closingFee, and liquiationPenalty
    constructor(address ethPool_, address usdc_, address borrower_, uint256 maxLiquidationRatio_, uint256 closingFee_, uint256 liquiationPenalty_) ERC721("EthColateralUsdcBorrowed", "cETHbUSDC") {
        _ethPool = ILoaner(ethPool_);
        _usdc = IERC20(usdc_);
    }

    //eth doesn't have an address
    function suppliedAsset() external pure returns(address){
        return address(0);
    }

    function borrowedAsset() external view returns(address){
        return address(_usdc);
    }

    function depositColateral(address receiver) external payable returns(uint256 loanId){
        require(balanceOf(receiver)==0,"Cannot have more than 1 outstanding loan");
        count=count+1;
        _depositedETH[count] = msg.value;
        _maxLiquiadtionRatio[count] = _currMaxLiquidationRatio;
        _closingFee[count] = _currClosingFee;
        _liquidationPenalty[count] = _currLiquidationPenalty;
        //now backed 1 to 1, most loan functionality is done will and the sfxseth will be added
        //will have to swap using frax contracts
        _sfxsEthRatioAtOpening[count] = 1;
        //mint nft last
        _safeMint(receiver, count);
        return count;
    }

    function addColateral(uint256 loanID, uint256 amount) external returns(uint256 totalColateral){

    }

    //function borrow(uint256 loanId, uint256 amount_, address sendTo_) external returns(uint256 amount);

    //function maxBorrow(uint256 loanId, address sendTo_) external returns(uint256 amount);

    //function liquidityRatio(uint256 loanId) external returns(uint256 amount);

    //function poke(address sendRewards_) external returns(uint256 amount);

}