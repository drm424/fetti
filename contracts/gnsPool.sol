// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

import "./IPool.sol";
import "./ILoaner.sol";
import "./IGnsStaker.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC721/ERC721.sol";
import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract gnsPool is IPool, ERC721{

    event LoanOpen(address mintor, uint256 tokenId, uint256 amount);
    event AddedColateral(uint256 tokenId, uint256 amount);
    event StakedColateral(uint256 amount);
    event LoanClose(address receiver, uint256 tokenId, uint256 amount);
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
    }

    mapping(uint256=>Loan) private _outstandingLoans;
    uint256 private _count;

    uint256 private _currLoanedOut;
    uint256 private _totalColateral;
    //6 decimal representation of dai harvested per colateral token
    uint256 private _daiRatio;
    
    address private _gov;
    IERC20 private immutable _usdc;
    IERC20 private _gns;
    IGnsStaker private _IGnsStaker = IGnsStaker(0xFb06a737f549Eb2512Eb6082A808fc7F16C0819D);
    ILoaner private _loaner;
    uint256 private _loanerId;
    address private _vault;

    uint256 private _borrowerSplit;
    uint256 private _lenderSplit;
    uint256 private _projectSplit;

    uint256 private _lowerLiq;
    uint256 private _higherLiq;

    //for testing only delete upon launch
    uint256 private _gnsPrice;
   
    constructor(address loaner_, address usdc_, address gns_, address vault_) ERC721("Fetti GNS Colateralized Loan", "FetGns") {
        _gov = msg.sender;
        _usdc = IERC20(usdc_);
        _loaner = ILoaner(loaner_);
        _gns = IERC20(gns_);
        _vault = vault_;
        _daiRatio = 0;
        _count = 0;
        _currLoanedOut = 0;

        _borrowerSplit = 20;
        _lenderSplit = 70;
        _projectSplit = 10;

        _lowerLiq=(3275*1e14);
        _higherLiq=(4275*1e14);

        //for testing only delete upon launch
        _gnsPrice=7000000;
    }

    function setLoanerId(uint256 poolId_) external returns(uint256){
        require(msg.sender==_gov,"only gov!!!");
        _loanerId = poolId_;
        return _loanerId;
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
        //collect rewards
        _count+=1;
        //chainlink time oracle here + the users inputted lock time 
        uint256 unlockTime = block.timestamp + 1;
        _gns.transferFrom(msg.sender, address(this), amount_);
        //stake(amount_);
        _outstandingLoans[_count] = Loan(_count,_daiRatio,amount_,0,unlockTime,(5*1e17),(6*1e17));
        _safeMint(receiver_, _count);
        _totalColateral+=amount_;
        emit LoanOpen(msg.sender,_count,amount_);
        return _count;
    }

    function addColateral(uint256 loanId_, uint256 amount_) external returns(uint256){
        require(msg.sender==ownerOf(loanId_),"Loan doesn't exist or you are not the owner of the loan");
        require(_gns.balanceOf(msg.sender)>=amount_, "don't have enough gns");
        require(_gns.allowance(msg.sender, address(this))>=amount_, "must have enough tokens approved in the gns contract");
        _gns.transferFrom(msg.sender, address(this), amount_);
        //collect rewards
        //increases to the average reward weight is less for new colateral
        //stake(amount_);
        //uint256 rewards = (_daiRatio-_outstandingLoans[loanId_].daiRatioPayout)*stakedAmount;
        //splitRewards(rewards, msg.sender);  
        _outstandingLoans[loanId_].daiRatioPayout=_daiRatio;
        _outstandingLoans[loanId_].stakedGns+=amount_;
        _totalColateral+=amount_;
        emit AddedColateral(loanId_, amount_);
        return _outstandingLoans[loanId_].stakedGns;
    }

    function stake(uint256 amount_) internal{
        _gns.approve(address(_IGnsStaker), amount_);
        _IGnsStaker.stakeTokens(amount_);
        emit StakedColateral(amount_);
    }

    function widthdrawColateral(address receiver_, uint256 loanId_) external returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        require(_outstandingLoans[loanId_].unlockTime<block.timestamp,"Colateral is still locked");
        require(_outstandingLoans[loanId_].borrowedUsdc==0,"Must repay entire loan before removing colateral");
        require(msg.sender==ownerOf(loanId_),"Must be the owner of the loan");
        //collect rewards
        uint256 amount = _outstandingLoans[loanId_].stakedGns + 0;
        uint256 stakedAmount = _outstandingLoans[loanId_].stakedGns;
        uint256 rewards = (_daiRatio-_outstandingLoans[loanId_].daiRatioPayout)*stakedAmount;
        //unstake(stakedAmount);
        _totalColateral-=amount;
        _closeLoan(loanId_);
        _gns.transfer(receiver_, amount);   
        emit LoanClose(receiver_, loanId_, amount);  
        //splitRewards(rewards, msg.sender);   
        return amount;
    }

    function unstake(uint256 amount_) internal{
        uint256 amount = _IGnsStaker.pendingRewardDai();
        require(((amount*(10**6))/_totalColateral)>0,"must be enough dai to harvest!!");
        _IGnsStaker.unstakeTokens(amount_);
        _daiRatio+=((amount*(10**6))/_totalColateral);
    }

    function splitRewards(uint256 amount_, address borrower_) internal{
        _usdc.transfer(_vault,(amount_*_lenderSplit)/100);
        _usdc.transfer(borrower_,(amount_*_borrowerSplit)/100);
        _usdc.transfer(address(0),(amount_*_projectSplit)/100);
    }

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256){
        require(_exists(loanId_),"Loan doesnt exist");
        require(getNewHealth(loanId_, amount_)<(_outstandingLoans[loanId_].maxBorrowedUsdc*1e4), "Requesting too much usdc");
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

    function totalColateral(uint256 loanId_) public view returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        return _outstandingLoans[loanId_].stakedGns;
    }

    function totalBorrow(uint256 loanId_) public view returns(uint256){
        require(_exists(loanId_),"loanId must be a open loan");
        return _outstandingLoans[loanId_].borrowedUsdc;
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
    function getNewHealth(uint256 loanId_, uint256 amount_) public view returns(uint256){
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
        return _gnsPrice;
    }

    function changeGnsPrice(uint256 amount_) public {
        require(msg.sender==_gov);
        _gnsPrice = amount_;
    }

    //purely for testing
    function exists(uint256 tokenId) public view returns (bool) {
        return _ownerOf(tokenId) != address(0);
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

    //for testing only. remove upon launch
    function changeDaiRatio(uint256 amount_) external{
        _daiRatio = amount_;
    }

    //for testing only. remove upon launch
    function getDaiRatio(uint256 loanId_) external view returns(uint256){
        return _outstandingLoans[loanId_].daiRatioPayout;
    }

    //for testing only. remove upon launch
    function getStakedGns(uint256 loanId_) external view returns(uint256){
        return _outstandingLoans[loanId_].stakedGns;
    }
}