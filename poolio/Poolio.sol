// SPDX-FileCopyrightText: 2021 ShardLabs
// SPDX-License-Identifier: GPL-3.0
pragma solidity ^0.8.0;

import "../node_modules/@openzeppelin/contracts/token/ERC20/IERC20.sol";
import "./IGnsStaker.sol";
//import "./TWAPPriceGetter.sol";

contract Poolio{

    event Test(uint256 x, uint256 y, uint256 z);

    //TWAPPriceGetter private gnsPriceFeed = TWAPPriceGetter(0x631e885028E75fCbB34C06d8ecB8e20eA18f6632);
    IGnsStaker private gnsStaker = IGnsStaker(0xFb06a737f549Eb2512Eb6082A808fc7F16C0819D);
    IERC20 private gns = IERC20(0xE5417Af564e4bFDA1c483642db72007871397896);
    IERC20 private dai = IERC20(0x8f3Cf7ad23Cd3CaDbD9735AFf958023239c6A063);

    address private a = 0x7bacdcf45f0515ed44618f94F64dc13541bc441B;
    address private b = 0xE852fD135f6740cBd460Ee6002CF049B1071bF11;
    address private c = 0xD4662845BaA196C42Fe57784255e08dD85536c5C;

    address private gov;

    mapping(address=>uint256) colateral;
    mapping(address=>uint256) daiRatio;
    uint256 totalColateral;

    uint256 immutable shiftingConstant = 1e18;

    //has 10 decimal places
    //represents the amount of dai earned on 10**18 tokens of colateral
    //might not work 
    uint256 currDaiRatio;

    constructor(){
        gov=msg.sender;
        currDaiRatio=0;
        totalColateral=0;
    }

    //amount_ may need to be at minimum enough tokens to cover then shifting contract
    function stakeGns(uint256 amount_) external{
        if(totalColateral!=0){
            updateDaiRatio();
        }
        daiRatio[msg.sender]= currDaiRatio;
        gns.transferFrom(msg.sender, address(this), amount_);
        gns.approve(address(gnsStaker), amount_);
        gnsStaker.stakeTokens(amount_);
        totalColateral+=amount_;
        colateral[msg.sender]=amount_;
        emit Test(1,amount_,0);
    }

    function takeGns(uint256 amount_) external{
        require(colateral[msg.sender]>=amount_);
        updateDaiRatioAndUnstake(amount_);
        colateral[msg.sender]-=amount_;
        totalColateral-=amount_;
        gns.transfer(msg.sender,amount_);
        splitDai(msg.sender,(amount_*(currDaiRatio-daiRatio[msg.sender])/shiftingConstant));
    }

    function updateDaiRatio() public{
        uint256 amount = pendingDai();
        gnsStaker.harvest();
        //this needs to have decimal places
        currDaiRatio+=(amount*shiftingConstant/totalColateral);
    }

    function updateDaiRatioAndUnstake(uint256 gnsAmount) internal{
        uint256 amount = pendingDai();
        gnsStaker.unstakeTokens(gnsAmount);
        //this needs to have decimal places
        currDaiRatio+=(amount*shiftingConstant/totalColateral);
    }

    
    function splitDai(address x, uint256 amount) internal{
        dai.transfer(x,(amount*60)/100);
        dai.transfer(x,(amount*25)/100);
        dai.transfer(x,(amount*15)/100);
    }

    function pendingDai() public view returns(uint256){
        return gnsStaker.pendingRewardDai();
    }

    function daiBal() external view returns(uint256){
        return dai.balanceOf(address(this));
    } 

    function gnsBal() external view returns(uint256){
        return gns.balanceOf(address(this));
    }

    function colateralAmount(address x) external view returns(uint256){
        return colateral[x];
    }

    function colateralDaiRatio(address x ) external view returns(uint256){
        return daiRatio[x];
    }

    function getCurrDaiRatio() external returns(uint256){
        updateDaiRatio();
        return currDaiRatio;
    }

    function getDaiRatio() external view returns(uint256){
        return currDaiRatio;
    }

    /**
    function getGNSPrice() public view returns(uint256 amount){
       return gnsPriceFeed.tokenPriceDai(); 
    }
    **/
}