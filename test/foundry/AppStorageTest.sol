// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.23 <0.9.0;

import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {Tokens} from "../../contracts/AppStorage.sol";
import {StateVars} from "../../contracts/StateVars.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
// import {IERC20} from "../../contracts/interfaces/IERC20.sol";

import "forge-std/console.sol";


contract AppStorageTest is StateVars {

    using FixedPointMathLib for uint;

    //EmptySwap means no swap aggregator is involved
    SwapData public emptySwap; 

    // EmptyLimit means no limit order is involved
    LimitOrderData public emptyLimit;

    // DefaultApprox means no off-chain preparation is involved, more gas consuming (~ 180k gas)
    ApproxParams public defaultApprox = ApproxParams(0, type(uint256).max, 0, 256, 1e14);

    /// @notice create a simple TokenInput struct without using any aggregators. For more info please refer to
    /// IPAllActionTypeV3.sol
    function createTokenInputStruct(address tokenIn, uint256 netTokenIn) internal view returns (TokenInput memory) {
        return TokenInput({
            tokenIn: tokenIn,
            netTokenIn: netTokenIn,
            tokenMintSy: tokenIn,
            pendleSwap: address(0),
            swapData: emptySwap
        });
    }

    /// @notice create a simple TokenOutput struct without using any aggregators. For more info please refer to
    /// IPAllActionTypeV3.sol
    function createTokenOutputStruct(
        address tokenOut,
        uint256 minTokenOut
    )
        internal
        view
        returns (TokenOutput memory)
    {
        return TokenOutput({
            tokenOut: tokenOut,
            minTokenOut: minTokenOut,
            tokenRedeemSy: tokenOut,
            pendleSwap: address(0),
            swapData: emptySwap
        });
    }


    function _getTokenOut(Tokens token_) internal pure returns(address tokenOut) {
        if (token_ == Tokens.sDAI) {
            tokenOut = address(sDAI);
        } else if (token_ == Tokens.FRAX) {
            tokenOut = address(FRAX);
        } else if (token_ == Tokens.USDC) {
            tokenOut = address(USDC);
        } else if (token_ == Tokens.WETH) {
            tokenOut = address(WETH);
        } else if (token_ == Tokens.WBTC) {
            tokenOut = address(WBTC);
        } else if (token_ == Tokens.USDe) {
            tokenOut = address(USDe);
        } else if (token_ == Tokens.sUSDe) {
            tokenOut = address(sUSDe);
        }
    }

    function _advanceInTime(uint amountTime_, address intAcc_, address token_) internal {
        uint borrowAPYformatted = OZ.getBorrowingRates(token_, true);
        (uint supplyAPYformatted, uint pendleFixedAPY) = OZ.getSupplyRates(token_, true);
        address debtToken;
        address aToken;

        if (token_ == address(USDC)) {
            debtToken = address(aaveVariableDebtUSDC);
            aToken = address(aUSDC);
        }

        //BORROWING
        uint monthlyBorrowingInterests = _calculateInterests(debtToken, intAcc_, borrowAPYformatted) / 12;
        uint debtBalance = IERC20(debtToken).balanceOf(intAcc_) + monthlyBorrowingInterests;

        //LENDING
        uint monthlyLendingInterests = _calculateInterests(aToken, intAcc_, supplyAPYformatted) / 12; 
        uint supplyBalance = IERC20(aToken).balanceOf(intAcc_) + monthlyLendingInterests;

        //PENDLE FIXED APY
        console.log('pendleFixedAPY: ', pendleFixedAPY);

        //----------
        //- the output of this would be sUSDe worth the fixed APY more than the USDe or USDC worth of the sUSDe initially used to buy the PT.
        //- so if initially i used 100 USDe/USDC to buy 90 sUSDe to then swap for 95 PT, at the end of the maturity, those
        // 95 PT will be worth 102 USDe/USDC worth of sUSDe
        //- code this ^ below
        (uint256 netTokenOut,,) = pendleRouter.swapExactPtForToken(
            address(this), address(sUSDeMarket), netPtOut, createTokenOutputStruct(address(sUSDe), 0), emptyLimit
        );
        //---------- <------------

        revert('here55');
        
        vm.warp(block.timestamp + amountTime_); 

        //Mocks borrowing interest accrual
        vm.mockCall(
            debtToken, 
            abi.encodeWithSelector(IERC20(debtToken).balanceOf.selector, intAcc_), 
            abi.encode(debtBalance)
        );

        //Mocks lending interest accrual
        vm.mockCall(
            aToken, 
            abi.encodeWithSelector(IERC20(aToken).balanceOf.selector, intAcc_), 
            abi.encode(supplyBalance)
        );
    }

    //calculates the anual interests of supply/borrow
    function _calculateInterests(address interestToken_, address intAcc_, uint formattedAPY_) internal view returns(uint) {
        uint FORMAT = 1e6; //due to being USDC with 6 decimals
        uint principal = IERC20(interestToken_).balanceOf(intAcc_);
        uint gainedInterests = formattedAPY_.mulDivDown(principal, 100) / FORMAT;

        return gainedInterests;
    }
}