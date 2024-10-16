// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity >=0.8.23 <0.9.0;

import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {Tokens} from "../../contracts/AppStorage.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
// import {IERC20} from "../../contracts/interfaces/IERC20.sol";
import {StateVars} from "@contracts/StateVars.sol";

import "forge-std/console.sol";


contract AppStorageTest is StateVars {

    using FixedPointMathLib for uint;

    //EmptySwap means no swap aggregator is involved
    SwapData public emptySwap; 

    // EmptyLimit means no limit order is involved
    LimitOrderData public emptyLimit;

    // DefaultApprox means no off-chain preparation is involved, more gas consuming (~ 180k gas)
    ApproxParams public defaultApprox = ApproxParams(0, type(uint256).max, 0, 256, 1e14);


    struct APYs {
        uint borrowAPYformatted;
        uint supplyAPYformatted;
        uint pendleFixedAPYformatted;
    }

    // mapping(Model model => Params params) interestRateModels;

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


    function _advanceInTime2(uint amountTime_, address intAcc_, address token_) internal {
        uint borrowAPYformatted = OZ.getBorrowingRates(token_, true);
        (uint supplyAPYformatted, uint pendleFixedAPYformatted) = OZ.getSupplyRates(token_, true);
        address debtToken;
        address aToken;

        APYs memory apys = APYs(borrowAPYformatted, supplyAPYformatted, pendleFixedAPYformatted);

        if (token_ == address(USDC)) {
            debtToken = address(aaveVariableDebtUSDC);
            aToken = address(aUSDC);
        }

        (
            uint debtBalance, 
            uint supplyBalance, 
            uint postPendleBalance
        ) = _calculateMoneyBalances(debtToken, aToken, intAcc_, apys);
        
        // vm.warp(block.timestamp + amountTime_); 

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

        //Mocks pendle's fixed APY accrual
        vm.mockCall(
            address(USDC), 
            abi.encodeWithSelector(USDC.balanceOf.selector, address(OZ)), 
            abi.encode(postPendleBalance)
        );
    }


    //calculates the anual interests of supply/borrow
    function _calculateInterests(address interestToken_, address user_, uint formattedAPY_) internal view returns(uint) {
        uint FORMAT = 1e6; //due to being USDC with 6 decimals
        uint principal = IERC20(interestToken_).balanceOf(user_);
        uint gainedInterests = formattedAPY_.mulDivDown(principal, 100) / FORMAT;

        return gainedInterests;
    }


    function _swapUni(
        address tokenIn_,
        address tokenOut_,
        address receiver_,
        uint amountIn_, 
        uint minAmountOut_
    ) internal returns(uint) {
        ISwapRouter swapRouterUni = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        // IERC20(tokenIn_).safeApprove(address(swapRouterUni), amountIn_); //<--- not working dont know why
        IERC20(tokenIn_).approve(address(swapRouterUni), amountIn_);
        uint24 poolFee = 500;

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenIn_, poolFee, address(USDT), poolFee, tokenOut_), //500 -> 0.05
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minAmountOut_
            });

        return swapRouterUni.exactInput(params);
    }


    function _calculateMoneyBalances(
        address debtToken_, 
        address aToken_, 
        address intAcc_,
        APYs memory apys_
    ) private returns(uint, uint, uint) {
        //Borrowing
        uint monthlyBorrowInterests = _calculateInterests(debtToken_, intAcc_, apys_.borrowAPYformatted) / 12;
        uint debtBalance = IERC20(debtToken_).balanceOf(intAcc_) + monthlyBorrowInterests;

        //Lending
        uint monthlyLendingInterests = (_calculateInterests(aToken_, intAcc_, apys_.supplyAPYformatted) / 12);
        uint supplyBalance = IERC20(aToken_).balanceOf(intAcc_) + monthlyLendingInterests;

        //Pendle Fixed APY
        uint ptBalanceOZ = sUSDe_PT_26SEP.balanceOf(address(OZ));
        vm.startPrank(address(OZ));
        sUSDe_PT_26SEP.approve(address(pendleRouter), ptBalanceOZ);

        (uint256 amountOutsUSDe,,) = pendleRouter.swapExactPtForToken(
            address(OZ), //receiver - this should be internalAccount, as the other OZs here
            address(sUSDeMarket), 
            ptBalanceOZ, 
            createTokenOutputStruct(address(sUSDe), 0), 
            emptyLimit
        );

        uint amountOutUSDC = _swapUni(
            address(sUSDe), 
            address(USDC), 
            address(OZ), 
            amountOutsUSDe, 
            0
        );

        uint monthlyPendleInterests = (_calculateInterests(address(USDC), address(OZ), apys_.pendleFixedAPYformatted) / 12);
        uint postPendleBalance = amountOutUSDC + monthlyPendleInterests;
        vm.stopPrank();

        return (debtBalance, supplyBalance, postPendleBalance);
    }
}


struct SwapUni {
    address tokenIn;
    address tokenInt;
    address tokenOut;
}

enum Type {
    BUY,
    SELL
}