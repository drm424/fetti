// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./ILoaner.sol";
import "./IGnsStaker.sol";
import "./ITWAPPriceGetter.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";


contract gnsPool is IPool, ERC721{

    /** 
    event LoanOpen(address mintor, uint256 tokenId, uint256 amount);
    event AddedColateral(uint256 tokenId, uint256 amount);
    event LoanClose(address receiver, uint256 tokenId, uint256 amount);
    event StakedColateral(uint256 amount, uint256 tokenId);
    event UnstakedColateral(uint256 amount, uint256 tokenId);
    event SentLoan(uint256 tokenId, uint256 amount);
    event RepaidLoan(uint256 tokenId, address payer, uint256 amountRepaid, uint256 outstandingLoanValue);
    event Liquidation(uint tokenId, uint256 amountToVault, uint256 amountToBorrower, uint256 amountToFund);
    event NewDaiRatio(uint256 amount, uint256 timestamp);
    */

    struct Loan{
        uint256 daiRatioPayout;
        uint256 stakedGns;
        uint256 borrowedUsdc;
        uint256 unlockTime;
        uint256 maxBorrowedUsdc;
        uint256 maxHealthFactor;
        uint256 lowerLiq;
        uint256 higherLiq;
        uint256 lenderRewardsSplit;
        uint256 borrowerRewardsSplit;
        uint256 projectRewardsSplit;
    }

    struct LoanLiqudationPenalty{
        uint256 liquidationPenalty;
        uint256 liquidationLenderSplit;
        uint256 liquidationProjectSplit;
    }

    mapping(uint256=>Loan) public _outstandingLoans;
    mapping(uint256=>LoanLiqudationPenalty) public _loanLiqudations;

    uint256 private _count;
    uint256 private _currLoanedOut;
    uint256 private _totalColateral;

    uint256 public currDaiRatio;
    
    address private _gov;

    IERC20 private immutable _usdc = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);
    IERC20 private immutable _gns = IERC20(0xE5417Af564e4bFDA1c483642db72007871397896);
    IGnsStaker private immutable _IGnsStaker = IGnsStaker(0xFb06a737f549Eb2512Eb6082A808fc7F16C0819D);
    ITWAPPriceGetter private immutable _IGnsOracle = ITWAPPriceGetter(0x631e885028E75fCbB34C06d8ecB8e20eA18f6632);

    ILoaner private _loaner;
    address private _vault;

    uint256 public _lockTime;

    uint256 public  _borrowerSplit;
    uint256 public _lenderSplit;
    uint256 public _projectSplit;

    uint256 private _lowerLiq;
    uint256 private _higherLiq;

    uint256 private _maxLTV;
    uint256 private _minLTVLiq;

    uint256 private _liqPenalty;
    uint256 private _liqPenLender;
    uint256 private _liqPenProject;

    uint256 immutable shiftingConstant = 1e18;
   
    constructor(address loaner_, address vault_) ERC721("Fetti GNS", "FetGns") {
        _gov = msg.sender;
        _loaner = ILoaner(loaner_);
        _vault = vault_;
        currDaiRatio = 0;
        _count = 0;
        _currLoanedOut = 0;

        _borrowerSplit = 15;
        _lenderSplit = 70;
        _projectSplit = 15;

        _lowerLiq=(3275*1e14);
        _higherLiq=(4275*1e14);

        _maxLTV=(5*1e17);
        _minLTVLiq=(6*1e17);

        _liqPenalty = 10;
        _liqPenLender = 75;
        _liqPenProject = 25;

        _lockTime = 60;
    }

    function totalLoanedOut() external view returns(uint256){
        return _currLoanedOut;
    }

    function totalCollateral() external view returns(uint256){
        return _totalColateral;
    }

    function depositColateral(address receiver_, uint256 amount_) external returns(uint256){
        require(balanceOf(msg.sender)==0, "can only have one loan per address");
        if(_totalColateral!=0){
            updateDaiRatio();
        }
        _gns.transferFrom(msg.sender, address(this), amount_);
        uint256 unlockTime = block.timestamp + _lockTime;
        _count+=1;
        _outstandingLoans[_count] = Loan(currDaiRatio,0,0,unlockTime, _maxLTV, _minLTVLiq, _lowerLiq, _higherLiq, _lenderSplit, _borrowerSplit, _projectSplit);
        _loanLiqudations[_count] = LoanLiqudationPenalty(_liqPenalty, _liqPenLender, _liqPenProject);
        stakeGns(amount_, _count);
        _safeMint(receiver_, _count);
        //emit LoanOpen(receiver_, _count, amount_);
        return _count;
    }

    function addColateral(uint256 loanId_, uint256 amount_) external returns(uint256){
        require(msg.sender==ownerOf(loanId_),"Loan doesn't exist or you are not the owner of the loan");
        require(_gns.balanceOf(msg.sender)>=amount_, "don't have enough gns");
        require(_gns.allowance(msg.sender, address(this))>=amount_, "must have enough tokens approved in the gns contract");
        splitDai(loanId_);
        _gns.transferFrom(msg.sender, address(this), amount_);
        stakeGns(amount_,loanId_);
        //emit AddedColateral(loanId_, amount_);
        return _outstandingLoans[loanId_].stakedGns;
    }

    function widthdrawColateral(address receiver_, uint256 loanId_) external returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        require(_outstandingLoans[loanId_].unlockTime<block.timestamp,"Colateral is still locked");
        require(_outstandingLoans[loanId_].borrowedUsdc==0,"Must repay entire loan before removing colateral");
        require(msg.sender==ownerOf(loanId_),"Must be the owner of the loan");
        uint256 amount = _outstandingLoans[loanId_].stakedGns;
        splitDai(loanId_);   
        takeGns(amount, loanId_, receiver_);
        _closeLoan(loanId_);
        //emit LoanClose(receiver_, loanId_, amount);  
        return amount;
    }

    function stakeGns(uint256 amount_, uint256 loanId_) internal{
        if(_totalColateral!=0){
            updateDaiRatio();
        }
        _outstandingLoans[loanId_].daiRatioPayout = currDaiRatio;
        _gns.approve(address(_IGnsStaker), amount_);
        _IGnsStaker.stakeTokens(amount_);
        _totalColateral+=amount_;
        _outstandingLoans[loanId_].stakedGns+=amount_;
        //emit StakedColateral(amount_, loanId_);
    }

    function updateDaiRatio() public{
        uint256 amount = pendingDai();
        _IGnsStaker.harvest();
        currDaiRatio+=(amount*shiftingConstant/_totalColateral);
        //emit NewDaiRatio(currDaiRatio, block.timestamp);
    }

    function pendingDai() public view returns(uint256){
        return _IGnsStaker.pendingRewardDai();
    }

    function lenderSplit() public view returns(uint256){
        return _lenderSplit;
    }

    function takeGns(uint256 amount_, uint256 loanId_, address receiver_) internal{
        require(_outstandingLoans[loanId_].stakedGns>=amount_);
        _outstandingLoans[loanId_].stakedGns-=amount_;
        updateDaiRatioAndUnstake(amount_);
        _gns.transfer(receiver_,amount_);
        //emit UnstakedColateral(amount_, loanId_);
    }

    function updateDaiRatioAndUnstake(uint256 gnsAmount) internal{
        uint256 amount = pendingDai();
        uint256 prevTotal = _totalColateral;
        _totalColateral-= gnsAmount;
        _IGnsStaker.unstakeTokens(gnsAmount);
        currDaiRatio+=(amount*shiftingConstant/prevTotal);
        //emit NewDaiRatio(currDaiRatio, block.timestamp);
    }

    function splitDai(uint256 loanId_) internal{
        //use loan terms to send the rewards
        updateDaiRatio();
        uint256 rewards = (_outstandingLoans[loanId_].stakedGns*(currDaiRatio-_outstandingLoans[loanId_].daiRatioPayout)/shiftingConstant);
        _outstandingLoans[loanId_].daiRatioPayout=currDaiRatio;
        _usdc.transfer(_vault,(rewards*_outstandingLoans[loanId_].lenderRewardsSplit)/100);
        _usdc.transfer(ownerOf(loanId_),(rewards*_outstandingLoans[loanId_].borrowerRewardsSplit)/100);
        _usdc.transfer(_gov,(rewards*_outstandingLoans[loanId_].projectRewardsSplit)/100);
    }

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256){
        require(_exists(loanId_),"Loan doesnt exist");
        require(getNewBorrowHealth(loanId_, amount_)<(_outstandingLoans[loanId_].maxBorrowedUsdc), "Requesting too much usdc");
        require(msg.sender==ownerOf(loanId_),"must be owner");
        require(_loaner.poolFreeDai()>=amount_,"loaner does not have enough usdc to cover your amount");
        _currLoanedOut+=amount_;
        _outstandingLoans[loanId_].borrowedUsdc+=amount_;
        _loaner.sendLoan(sendTo_,amount_);
        //emit SentLoan(loanId_, amount_);
        return amount_;
    }

    function repayLoan(uint256 loanId_, uint256 amount_) external returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        require(amount_<=_outstandingLoans[loanId_].borrowedUsdc,"amount must be greater than 0 and less than your loaned out amount");
        _usdc.transferFrom(msg.sender,_vault,amount_);
        _currLoanedOut-=amount_;
        _outstandingLoans[loanId_].borrowedUsdc-=amount_;
        //emit RepaidLoan(loanId_, msg.sender, amount_, _outstandingLoans[loanId_].borrowedUsdc);
        return _outstandingLoans[loanId_].borrowedUsdc;
    }
 
    function liquidate(uint256 loanId_,uint256 amount_,address payer_) external{
        LoanLiqudationPenalty memory loanPens = _loanLiqudations[loanId_]; 
        Loan memory loan = _outstandingLoans[loanId_];               
        require(loan.maxHealthFactor<getCurrHealth(loanId_));
        uint256 newHealth = getNewLiqHealth(loanId_,amount_);
        require(loan.lowerLiq<=newHealth && loan.higherLiq>=newHealth);

        _usdc.transferFrom(payer_,address(this),amount_);
        _outstandingLoans[loanId_].borrowedUsdc-=amount_;
        
        uint256 gnsSend = gnsToSend(amount_);
        _outstandingLoans[loanId_].stakedGns-=gnsSend;
        _gns.transfer(msg.sender, gnsSend);
        
        uint256 x = (loanPens.liquidationPenalty*loan.stakedGns)/100;
        _outstandingLoans[loanId_].stakedGns-=x;
        _gns.transfer(address(_vault),((loanPens.liquidationLenderSplit*x)/100));
        _gns.transfer(address(_gov),((loanPens.liquidationProjectSplit*x)/100));
    }

    function getCurrHealth(uint256 loanId_) public view returns(uint256){
        uint256 borrowedAmountShifted = _outstandingLoans[loanId_].borrowedUsdc * 1e18;
        uint256 collateralValueShifted = _outstandingLoans[loanId_].stakedGns * currGnsPrice();
        uint256 healthFactorShifted = (borrowedAmountShifted * 1e6) / collateralValueShifted;
        return healthFactorShifted;
    }

    function getNewBorrowHealth(uint256 loanId_, uint256 amount_) public view returns(uint256){
        uint256 healthFactorShifted = ((_outstandingLoans[loanId_].borrowedUsdc+amount_) * 1e18) * 1e6 / (_outstandingLoans[loanId_].stakedGns * currGnsPrice());
        return healthFactorShifted;
    }

    function getNewLiqHealth(uint256 loanId_, uint256 amount_) public view returns(uint256){
        uint256 healthFactorShifted = ((_outstandingLoans[loanId_].borrowedUsdc-amount_) * 1e18) * 1e6 / ((_outstandingLoans[loanId_].stakedGns-gnsToSend(amount_)) * currGnsPrice());
        return healthFactorShifted;
    }

    function gnsToSend(uint256 amount_) public view returns(uint256){
        uint256 gnsprice = currGnsPrice();
        return (((amount_*1175*(1e6))/1000)+gnsprice-1)/gnsprice;
    }

    function currGnsPrice() public view returns(uint256){
        uint256 price6decimals = _IGnsOracle.tokenPriceDai()/(1e4);
        return price6decimals;
    }

    /** 
    function changeLTVandMaxHF(uint256 lowerLiq_, uint256 higherLiq_, uint256 maxLTV_, uint256 minLTVLiq_) public{
        require(msg.sender==_gov);
        _lowerLiq=lowerLiq_;
        _higherLiq=higherLiq_;
        _maxLTV=maxLTV_;
        _minLTVLiq=minLTVLiq_;
    }

    function changeLiquidationPenalties(uint256 liqPenalty_, uint256 liqPenLender_, uint256 liqPenProject_) public{
        require(msg.sender==_gov);
        _liqPenalty = liqPenalty_;
        _liqPenLender = liqPenLender_;
        _liqPenProject = liqPenProject_;
    }

    function changeRewardsSplit(uint256 borrowerSplit_, uint256 lenderSplit_, uint256 projectSplit_) public{
        require(msg.sender==_gov);
        _borrowerSplit = borrowerSplit_;
        _lenderSplit = lenderSplit_;
        _projectSplit = projectSplit_;
    }

    function changeContracts(address vault_, address loaner_) public{
        require(msg.sender==_gov);
        _vault = vault_;
        _loaner = ILoaner(loaner_);
    }
    */

    function _closeLoan(uint256 loanId_) private{
        delete _outstandingLoans[loanId_];
        delete _loanLiqudations[loanId_];
        _burn(loanId_);
    }
}