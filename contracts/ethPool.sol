// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./ILoaner.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ethPool is IPool, ERC721{

    event LoanOpen(address mintor, uint256 tokenId, uint256 amount);
    event AddedColateral(uint256 tokenId, uint256 amount);
    event LoanClose(address receiver, uint256 tokenId, uint256 amount);

    event SentLoan(uint256 tokenId, uint256 amount);

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
    uint256 private _currLoanedOut;
    
    address private _gov;
    IERC20 private immutable _usdc;
    ILoaner private _loaner;
    uint256 private _loanerId;
    address private _vault;
   
    constructor(address loaner_, address usdc_, address vault_) ERC721("Fetti Eth Colateralized Loan", "FetEth") {
        _gov = msg.sender;
        _usdc = IERC20(usdc_);
        _loaner = ILoaner(loaner_);
        _count = 0;
        _vault = vault_;
    }

    function setLoanerId(uint256 poolId_) external returns(uint256 id){
        require(msg.sender==_gov,"only gov!!!");
        _loanerId = poolId_;
        return _loanerId;
    }

    //add global var and track loaned out amounts with each borrow and repayment
    function totalLoanedOut() external view returns(uint256 amount){
        return _currLoanedOut;
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
        require(_exists(loanId_),"loanId must be a open loan");
        require(_outstandingLoans[loanId_].unlockTime<block.timestamp,"Colateral is still locked");
        require(_outstandingLoans[loanId_].borrowedUsdc==0,"Must repay entire loan before removing colateral");
        require(msg.sender==ownerOf(loanId_),"Must be the owner of the loan");
        uint256 amount = _outstandingLoans[loanId_].depositedEth + 0;
        delete _outstandingLoans[loanId_];
        _burn(loanId_);
        receiver_.transfer(amount);   
        emit LoanClose(receiver_, loanId_, amount);     
        return amount;
    }

    function totalColateral(uint256 loanId_) public view returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        return _outstandingLoans[loanId_].depositedEth;
    }

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256 amount){
        require(_exists(loanId_),"Loan doesnt exist");
        require(getNewHealth(loanId_, amount_)<(7*1e5), "Requesting too much usdc");
        require(msg.sender==ownerOf(loanId_),"must be owner");
        require(_loaner.poolFreeUsdc(1)!=0,"loaner does not have enough usdc to cover your amount");
        _currLoanedOut+=amount_;
        _outstandingLoans[loanId_].borrowedUsdc+=amount_;
        _loaner.sendLoan(sendTo_,_loanerId,amount_);
        emit SentLoan(loanId_, amount_);
        return amount_;
    }

    function totalBorrow(uint256 loanId_) public view returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        return _outstandingLoans[loanId_].borrowedUsdc;
    }

    //returns percentage with 4 decimals
    function getCurrHealth(uint256 loanId_) public view returns(uint256){
        uint256 healthFactor1e6 = (_outstandingLoans[loanId_].borrowedUsdc*1e18)/(currEthPrice()*_outstandingLoans[loanId_].depositedEth);
        return healthFactor1e6;
    }

    //returns percentage with 4 decimals
    function getNewHealth(uint256 loanId_, uint256 amount_) public view returns(uint256){
        uint256 healthFactor1e6 = ((_outstandingLoans[loanId_].borrowedUsdc+amount_)*1e18)/(currEthPrice()*_outstandingLoans[loanId_].depositedEth);
        return healthFactor1e6;
    }

    //not exactly sure of the correct order of these transactions
    function repayLoan(uint256 loanId_, uint256 amount_) public returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        require((amount_>0)&&(amount_<=_outstandingLoans[loanId_].borrowedUsdc),"amount must be greater than 0 and less than your loaned out amount");
        _usdc.transferFrom(msg.sender,_vault,amount_);
        _currLoanedOut-=amount_;
        _outstandingLoans[loanId_].borrowedUsdc-=amount_;
        return _outstandingLoans[loanId_].borrowedUsdc;
    }

    function maxBorrow(uint256 loanId_, address sendTo_) external pure returns(uint256 amount){
        return 0;
    }

    function poke(address sendRewards_) external pure returns(uint256 amount){
        return 0;
    }

    //eventually call chainlink price oracle here
    function currEthPrice() public pure returns(uint256 price){
        return 1000;
    }

    //purely for testing
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
    }
}