pragma solidity ^0.8.0;

import "./ILoan.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract Loan is ILoan, ERC721{

    address private _borrower;
    IERC20 private _usdc;
    uint256 public _depositedETH;
    uint256 public _borrowedUSDC;
    uint256 public _maxLiquiadtionRatio;


    constructor(address usdc_, address borrower_, uint256 maxLiquidationRatio_) ERC721("EthColateralUsdcBorrowed", "cETHbUSDC") {
        _borrower = borrower_;
        _usdc = IERC20(usdc_);
        _depositedETH = 0;
        _borrowedUSDC = 0;
        _maxLiquiadtionRatio = ((1 ether)/10)*8;
    }

    function borrowedAsset() external returns(address){
        return address(_usdc);
    }

    //eth doesn't have an address
    function suppliedAsset() external returns(address){
        return address(0);
    }

    function depositColateral(uint256 amount_) external payable returns(uint256 amount){
        require(msg.sender==_borrower);
        _depositedETH+=msg.value;
    }

    function borrow(uint256 amount_, address sendTo_) external returns(uint256 amount){
        require(_maxLiquiadtionRatio>());



    }

    function maxBorrow(address sendTo_) external returns(uint256 amount);

    function liquidityRatio() external returns(uint256 amount);

    function poke(address sendRewards_) external returns(uint256 amount);

}