// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./ILoanEth.sol";
import "./ILoaner.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ethLoan is ILoanEth, ERC721{

    event LoanOpen(address mintor, uint256 tokenId, uint256 amount);
    event AddedColateral(uint256 tokenId, uint256 amount);
    event LoanClose(address receiver, uint256 tokenId, uint256 amount);

    struct Loan{
        uint256 id;
        uint256 depositedEth;
        uint256 borrowedUsdc;
        uint256 unlockTime;
        uint256 maxHealthFactor;
        uint256 liquidationPenalty;
        uint256 borrowerSplit;
        uint256 lenderSplit;
        uint256 projectSplit;
    }

    mapping(uint256=>Loan) private _outstandingLoans;
    uint256 private _count;
    
    IERC20 private immutable _usdc;
    ILoaner private _ethPool;
   
    constructor(address ethPool_, address usdc_) ERC721("Fetti Eth Colateralized Loan", "FetEth") {
        _usdc = IERC20(usdc_);
        _ethPool = ILoaner(ethPool_);
        _count = 0;
    }

    //eth doesn't have an address
    function suppliedAsset() external pure returns(address){
        return address(0);
    }

    function borrowedAsset() external view returns(address){
        return address(_usdc);
    }

    //add global var and track loaned out amounts with each borrow and repayment
    function totalLoanedOut() external view returns(uint256 amount){
        return 0;
    }


    //not needed for eth
    function depositColateral(address receiver_, uint256 amount_) external pure returns(uint256 loanId){
        require(0==1, "This is an eth loan");
        return 0;
    }

    //not needed for eth
    function addColateral(uint256 loanId_, uint256 amount) external pure returns(uint256){
        require(0==1, "This is an eth loan");
        return 0;
    }

    //not needed for eth
    function widthdrawColateral(address receiver_, uint256 loanId_) external pure returns(uint256){
        require(0==1, "This is an eth loan");
        return 0;
    }

    //eventually change block.timestamp to chainlink oracle
    //after get loan functionality done swap to sfxseth
    function depositColateralEth() external payable returns(uint256){
        require(msg.value>0,"Must deposit eth!!!");
        require(balanceOf(msg.sender)==0, "can only have one loan per address");
        _count+=1;
        uint256 countLocal = _count;
        uint256 unlockTime = block.timestamp + 1;
        _outstandingLoans[countLocal] = Loan(countLocal,msg.value,0,unlockTime,80,10,45,45,10);
        _safeMint(msg.sender, countLocal);
        emit LoanOpen(msg.sender,countLocal,msg.value);
        return countLocal;
    }

    function addColateralEth(uint256 loanId_) external payable returns(uint256){      
        require(msg.value>0,"must send eth!!");
        require(msg.sender==ownerOf(loanId_),"Loan doesn't exist or you are not the owner of the loan");
        _outstandingLoans[loanId_].depositedEth+=msg.value;
        emit AddedColateral(loanId_, msg.value);
        return _outstandingLoans[loanId_].depositedEth;
    }

    //use the other stored loan info to take fees from the closure
    //remove loan information from mapping
    function widthdrawColateralEth(address payable receiver_, uint256 loanId_) external payable returns(uint256){
        require(_outstandingLoans[loanId_].unlockTime<block.timestamp,"Colateral is still locked");
        require(msg.sender==ownerOf(loanId_),"Must be the owner of the loan");
        uint256 amount = _outstandingLoans[loanId_].depositedEth;
        delete _outstandingLoans[loanId_];
        _burn(loanId_);
        require(receiver_.send(amount), "transation failed");   
        emit LoanClose(receiver_, loanId_, amount);     
        return amount;
    }

    function totalColateral(uint256 loanId_) public view returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        return _outstandingLoans[loanId_].depositedEth;
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

    //purely for testing
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}