// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;
import "./IPool.sol";

contract Pool is IPool {

    constructor(){
        
    }
    
    function totalLoanedOut() external view returns(uint256 amount){
        return 0;
    }

    function depositColateral(address receiver_, uint256 amount_) external returns(uint256){
        return 0;
    }

    function addColateral(uint256 loanId_, uint256 amount) external returns(uint256){
        return 0;
    }

    function widthdrawColateral(address receiver_, uint256 loanId_) external returns(uint256){
        return 0;
    }

    function borrow(uint256 loanId_, uint256 amount_, address payable sendTo_) external returns(uint256){
        return 0;
    }

    function repayLoan(uint256 loanId_, uint256 amount_) external returns(uint256){
        return 0;
    }

    function liquidate(uint256 loanId_,uint256 amount_,address payer_ ) external{
        uint256 t = 0;
    }

    function pendingDai() external view returns(uint256){
        return 0;
    }

    function lenderSplit() external view returns(uint256){
        return 0;
    }
}