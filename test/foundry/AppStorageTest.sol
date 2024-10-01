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
        (uint supplyAPYformatted,) = OZ.getSupplyRates(token_, true);
        address debtToken;
        address aToken;

        if (token_ == address(USDC)) {
            debtToken = address(aaveVariableDebtUSDC);
            aToken = address(aUSDC);
        }

        // uint debtBalance = IERC20(debtToken).balanceOf(intAcc_);
        // uint gainedInterests = borrowAPYformatted.mulDivDown(debtBalance, 100) / FORMAT;
        // uint totalDebt = debtBalance + gainedInterests;

        uint debtBalance = _calculateInterests(debtToken, intAcc_, borrowAPYformatted);
        console.log('debtBalance: ', debtBalance);
        console.log('');

        (uint supplyAPYnotFormatted,) = OZ.getSupplyRates(token_, false);
        console.log('supplyAPYnotFormatted: ', supplyAPYnotFormatted);
        
        uint supplyBalance = _calculateInterests(aToken, intAcc_, supplyAPYformatted); 
        console.log('supplyBalance: ', supplyBalance);

        revert('here44');
        
        vm.warp(block.timestamp + amountTime_); 

        vm.mockCall(
            address(aaveVariableDebtUSDC), 
            abi.encodeWithSelector(aaveVariableDebtUSDC.balanceOf.selector, intAcc_), 
            abi.encode(debtBalance)
        );
    }

    //calculates the interests of supply/borrow and adds it to the principal
    function _calculateInterests(address interestToken_, address intAcc_, uint formattedAPY_) internal view returns(uint) {
        uint FORMAT = 1e6; //due to being USDC with 6 decimals
        uint principal = IERC20(interestToken_).balanceOf(intAcc_);
        console.log('principal: ', principal);
        uint gainedInterests = formattedAPY_.mulDivDown(principal, 100) / FORMAT;
        
        console.log('gainedInterests: ', gainedInterests);
        console.log('formattedAPY_: ', formattedAPY_);

        return principal + gainedInterests;
    }
}