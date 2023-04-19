// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./ILoaner.sol";
import "./IGnsStaker.sol";
import "./ITWAPPriceGetter.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract gnsPool is IPool, ERC721{

    event Test(uint256 x, uint256 y, uint256 z);

    event LoanOpen(address mintor, uint256 tokenId, uint256 amount);
    event AddedColateral(uint256 tokenId, uint256 amount);
    event LoanClose(address receiver, uint256 tokenId, uint256 amount);
    event StakedColateral(uint256 amount, uint256 tokenId);
    event UnstakedColateral(uint256 amount, uint256 tokenId);
    event SentLoan(uint256 tokenId, uint256 amount);
    event RepaidLoan(uint256 tokenId, address payer, uint256 amountRepaid, uint256 outstandingLoanValue);
    event Liquidation(uint tokenId, uint256 amountToVault, uint256 amountToBorrower, uint256 amountToFund);

    //create mapping(address=>uint256) for percentage of accrrued rewards for each associated address
    //also need an array of address that will be paid to iterate through mapping to pay rewards
    struct Loan{
        uint256 id;
        uint256 daiRatioPayout;
        uint256 stakedGns;
        uint256 borrowedUsdc;
        uint256 unlockTime;
        uint256 maxBorrowedUsdc;
        uint256 maxHealthFactor;
        uint256 lowerLiq;
        uint256 higherLiq;
    }

    mapping(uint256=>Loan) public _outstandingLoans;
    uint256 private _count;

    uint256 private _currLoanedOut;
    uint256 private _totalColateral;

    //10 decimal representation of dai harvested per colateral token
    uint256 public currDaiRatio;
    
    address private _gov;

    IERC20 private immutable _usdc;
    IERC20 private _gns;
    IGnsStaker private _IGnsStaker;
    ITWAPPriceGetter private _IGnsOracle;

    ILoaner private _loaner;
    uint256 private _loanerId;
    address private _vault;

    uint256 private _borrowerSplit;
    uint256 private _lenderSplit;
    uint256 private _projectSplit;

    uint256 private _lowerLiq;
    uint256 private _higherLiq;

    uint256 private _maxLTV;
    uint256 private _minLTVLiq;


    uint256 immutable shiftingConstant = 1e18;
   
    constructor(address loaner_, address vault_) ERC721("Fetti GNS", "FetGns") {
        _gov = msg.sender;
        _usdc = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
        _gns = IERC20(0xE5417Af564e4bFDA1c483642db72007871397896);
        _IGnsStaker = IGnsStaker(0xFb06a737f549Eb2512Eb6082A808fc7F16C0819D);
        _IGnsOracle = ITWAPPriceGetter(0x631e885028E75fCbB34C06d8ecB8e20eA18f6632);
        _loaner = ILoaner(loaner_);
        _vault = vault_;
        currDaiRatio = 0;
        _count = 0;
        _currLoanedOut = 0;

        _borrowerSplit = 20;
        _lenderSplit = 70;
        _projectSplit = 10;

        _lowerLiq=(3275*1e14);
        _higherLiq=(4275*1e14);

        _maxLTV=(5*1e17);
        _minLTVLiq=(6*1e17);
    }

    //add global var and track loaned out amounts with each borrow and repayment
    function totalLoanedOut() external view returns(uint256){
        return _currLoanedOut;
    }

    //block.timestamp needs to be changed to chainlink oracle
    function depositColateral(address receiver_, uint256 amount_) external returns(uint256){
        require(balanceOf(msg.sender)==0, "can only have one loan per address");
        require(_gns.balanceOf(msg.sender)>=amount_, "don't have enough gns");
        require(_gns.allowance(msg.sender, address(this))>=amount_, "must have enough tokens approved in the gns contract");
        if(_totalColateral!=0){
            updateDaiRatio();
        }
        _count+=1;
        uint256 unlockTime = block.timestamp + 1;
        _gns.transferFrom(msg.sender, address(this), amount_);
        _totalColateral+=amount_;
        _outstandingLoans[_count] = Loan(_count,currDaiRatio,0,0,unlockTime, _lowerLiq, _higherLiq, _maxLTV, _minLTVLiq);
        stakeGns(amount_, _count);
        _safeMint(receiver_, _count);
        emit LoanOpen(receiver_, _count, amount_);
        return _count;
    }

    function addColateral(uint256 loanId_, uint256 amount_) external returns(uint256){
        require(msg.sender==ownerOf(loanId_),"Loan doesn't exist or you are not the owner of the loan");
        require(_gns.balanceOf(msg.sender)>=amount_, "don't have enough gns");
        require(_gns.allowance(msg.sender, address(this))>=amount_, "must have enough tokens approved in the gns contract");
        updateDaiRatio();
        splitDai(loanId_);
        _gns.transferFrom(msg.sender, address(this), amount_);
        stakeGns(amount_,loanId_);
        emit AddedColateral(loanId_, amount_);
        return _outstandingLoans[loanId_].stakedGns;
    }

    //needs to split the collected rewards
    function widthdrawColateral(address receiver_, uint256 loanId_) external returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        require(_outstandingLoans[loanId_].unlockTime<block.timestamp,"Colateral is still locked");
        //look into widthdrawing just enough to keep health factor over the max hf
        require(_outstandingLoans[loanId_].borrowedUsdc==0,"Must repay entire loan before removing colateral");
        require(msg.sender==ownerOf(loanId_),"Must be the owner of the loan");
        uint256 amount = _outstandingLoans[loanId_].stakedGns + 0;
        splitDai(loanId_);   
        takeGns(amount, loanId_);
        _closeLoan(loanId_);
        _gns.transfer(receiver_, amount);   
        emit LoanClose(receiver_, loanId_, amount);  
        return amount;
    }

    /**
     * need to split any collected rewards before calling this message
     */
    function stakeGns(uint256 amount_, uint256 loanId_) public{
        if(_totalColateral!=0){
            updateDaiRatio();
        }
        _outstandingLoans[loanId_].daiRatioPayout = currDaiRatio;
        _gns.approve(address(_IGnsStaker), amount_);
        _IGnsStaker.stakeTokens(amount_);
        _outstandingLoans[loanId_].stakedGns+=amount_;
        emit StakedColateral(amount_, loanId_);
    }

    function getDaiRatio() public view returns(uint256){
        return currDaiRatio;
    }

    function updateDaiRatio() public{
        uint256 amount = pendingDai();
        _IGnsStaker.harvest();
        currDaiRatio+=(amount*shiftingConstant/_totalColateral);
    }

    function pendingDai() public view returns(uint256){
        return _IGnsStaker.pendingRewardDai();
    }

    function takeGns(uint256 amount_, uint256 loanId_) public{
        require(_outstandingLoans[loanId_].stakedGns>=amount_);
        updateDaiRatioAndUnstake(amount_);
        _outstandingLoans[loanId_].stakedGns-=amount_;
        _totalColateral-=amount_;
        _gns.transfer(msg.sender,amount_);
        emit UnstakedColateral(amount_, loanId_);
    }

    function updateDaiRatioAndUnstake(uint256 gnsAmount) internal{
        uint256 amount = pendingDai();
        _IGnsStaker.unstakeTokens(gnsAmount);
        currDaiRatio+=(amount*shiftingConstant/_totalColateral);
    }

    function splitDai(uint256 loanId_) internal{
        //use loan terms to send the rewards
        uint256 rewards = (_outstandingLoans[loanId_].stakedGns*(currDaiRatio-_outstandingLoans[loanId_].daiRatioPayout)/shiftingConstant);
        _outstandingLoans[loanId_].daiRatioPayout=currDaiRatio;
        _usdc.transfer(_vault,(rewards*70)/100);
        _usdc.transfer(ownerOf(loanId_),(rewards*15)/100);
        _usdc.transfer(_gov,(rewards*15)/100);
    }

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256){
        require(_exists(loanId_),"Loan doesnt exist");
        require(getNewBorrowHealth(loanId_, amount_)<(_outstandingLoans[loanId_].maxBorrowedUsdc), "Requesting too much usdc");
        require(msg.sender==ownerOf(loanId_),"must be owner");
        require(_loaner.poolFreeDai()!=0,"loaner does not have enough usdc to cover your amount");
        _currLoanedOut+=amount_;
        _outstandingLoans[loanId_].borrowedUsdc+=amount_;
        _loaner.sendLoan(sendTo_,amount_);
        emit SentLoan(loanId_, amount_);
        return amount_;
    }

    //not exactly sure of the correct order of these transactions
    function repayLoan(uint256 loanId_, uint256 amount_) external returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        require(amount_<=_outstandingLoans[loanId_].borrowedUsdc,"amount must be greater than 0 and less than your loaned out amount");
        _usdc.transferFrom(msg.sender,_vault,amount_);
        _currLoanedOut-=amount_;
        _outstandingLoans[loanId_].borrowedUsdc-=amount_;
        emit RepaidLoan(loanId_, msg.sender, amount_, _outstandingLoans[loanId_].borrowedUsdc);
        return _outstandingLoans[loanId_].borrowedUsdc;
    }
 
    //dont use existing health functions, needs deposited gns not staked fns for liqs
    function liquidate(uint256 loanId_,uint256 amount_,address payer_) external{
        require(_outstandingLoans[loanId_].maxHealthFactor<getCurrHealth(loanId_));
        require(_lowerLiq<=getNewLiqHealth(loanId_,amount_)&&_higherLiq>=getNewLiqHealth(loanId_,amount_));
        _usdc.transferFrom(payer_,address(this),amount_);
        _outstandingLoans[loanId_].borrowedUsdc-=amount_;
        uint256 gnsSend = gnsToSend(amount_);
        _outstandingLoans[loanId_].stakedGns-=gnsSend;
        //split rewards before transfer of gns
        _gns.transfer(msg.sender, gnsSend);
        uint256 x = (10*_outstandingLoans[loanId_].stakedGns)/100;
        _outstandingLoans[loanId_].stakedGns-=x;
        _gns.transfer(address(_vault),((75*x)/100));
        _gns.transfer(address(_gov),((25*x)/100));
    }

    //dont use existing health functions, needs deposited gns not staked fns for liqs
    function close(uint256 loanId_) external{

    }

    //1e18 represents 100% health factor
    //**DON"T USE FOR LIQUIDATIONS ONLY BORROWING***
    function getCurrHealth(uint256 loanId_) public view returns(uint256){
        uint256 borrowedAmountShifted = _outstandingLoans[loanId_].borrowedUsdc * 1e18;
        uint256 collateralValueShifted = _outstandingLoans[loanId_].stakedGns * currGnsPrice();
        uint256 healthFactorShifted = (borrowedAmountShifted * 1e6) / collateralValueShifted;
        return healthFactorShifted;
    }

    //returns decimal value with 18 decimals, percentage with 16 decimals
    //***USES STAKED GNS TO FIND HEALTH***
    //**DON"T USE FOR LIQUIDATIONS ONLY BORROWING***
    function getNewBorrowHealth(uint256 loanId_, uint256 amount_) public view returns(uint256){
        uint256 healthFactorShifted = ((_outstandingLoans[loanId_].borrowedUsdc+amount_) * 1e18) * 1e6 / (_outstandingLoans[loanId_].stakedGns * currGnsPrice());
        return healthFactorShifted;
    }

    function getNewLiqHealth(uint256 loanId_, uint256 amount_) public view returns(uint256){
        uint256 healthFactorShifted = ((_outstandingLoans[loanId_].borrowedUsdc-amount_) * 1e18) * 1e6 / ((_outstandingLoans[loanId_].stakedGns-gnsToSend(amount_)) * currGnsPrice());
        return healthFactorShifted;
    }

    function gnsToSend(uint256 amount_) public view returns(uint256){
        //round up
        uint256 gnsprice = currGnsPrice();
        return (((amount_*1175*(1e6))/1000)+gnsprice-1)/gnsprice;
    }

    //make it call gns price aggregator, returns that price with 6 decimals
    function currGnsPrice() public view returns(uint256){
        uint256 price6decimals = _IGnsOracle.tokenPriceDai()/(1e4);
        return price6decimals;
    }

    function _closeLoan(uint256 loanId_) private{
        delete _outstandingLoans[loanId_];
        _burn(loanId_);
    }

     //not needed for erc-20
    function depositColateralEth() external payable returns(uint256){
        require(1==0,"is an erc-20 vault");
        return 0;        
    }

    //not needed for erc-20
    function addColateralEth(uint256 loanId_) external payable returns(uint256){      
        require(1==0,"is an erc-20 vault");
        return 0; 
    }

    //not needed for erc-20
    function widthdrawColateralEth(address payable receiver_, uint256 loanId_) external payable returns(uint256){
        require(1==0,"is an erc-20 vault");
        return 0; 
    }
}