pragma solidity ^0.8.0;

import "./ILoan.sol";
import "./IPool.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loan is ILoan, ERC721{

    address private _borrower;
    IPool private _ethPool;
    IERC20 private _usdc;

    uint256 public _depositedETH;
    uint256 public _borrowedUSDC;
    uint256 public _maxLiquiadtionRatio;
    uint256 public _closingFee;
    uint256 public _liquidationPenalty;

    //eventually change constructor to use the passed in maxiquidationRatio, closingFee, and liquiationPenalty
    constructor(address ethPool_, address usdc_, address borrower_, uint256 maxLiquidationRatio_, uint256 closingFee_, uint256 liquiationPenalty_) ERC721("EthColateralUsdcBorrowed", "cETHbUSDC") {
        _borrower = borrower_;
        _ethPool = IPool(ethPool_);
        _usdc = IERC20(usdc_);
        _depositedETH = 0;
        _borrowedUSDC = 0;
        _maxLiquiadtionRatio = ((1 ether)/10)*8;
        _closingFee = ((1 ether)/1000);
        _liquidationPenalty = ((1 ether)/10);
    }

    function borrowedAsset() external view returns(address){
        return address(_usdc);
    }

    //eth doesn't have an address
    function suppliedAsset() external pure returns(address){
        return address(0);
    }

    //needs to stake fxsEth to earn yeild
    function depositColateral(uint256 amount_) external payable returns(uint256 totalColateral){
        require(msg.sender==_borrower);
        _depositedETH+=msg.value;
        return _depositedETH;
    }

    function borrow(uint256 amount_, address sendTo_) external returns(uint256 amount){
        require(msg.sender==_borrower);
        require(_maxLiquiadtionRatio>(((_borrowedUSDC+amount_)*(10**12))/(_depositedETH)), "Requested amount liquidates your loan");
        require(_ethPool.totalFreeUSDC()>=amount_);
        IPool.requestUSDC(uint256)
        return 0;
    }

    //needs completion
    function maxBorrow(address sendTo_) external pure returns(uint256 amount){
        return 0;
    }

    //needs completion
    function liquidityRatio() external pure returns(uint256 amount){
        return 0;
    }

    //needs completion
    function poke(address sendRewards_) external pure returns(uint256 amount){
        return 0;
    }

}