// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {AppStorageTest, SwapUni, Type} from "@test/foundry/AppStorageTest.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {HelpersLib} from "@contracts/libraries/HelpersLib.sol";

import "forge-std/console.sol";
 

contract HelpersTest is AppStorageTest {

    using FixedPointMathLib for *;
    using HelpersLib for *;


    function _advanceInTime(uint amountTime_) internal {
        vm.warp(block.timestamp + amountTime_);
        
        uint netTotal = _addFixedAPY(
            OZ.getInternalSupplyRate(),
            amountTime_,
            true
        );
    
        vm.mockCall(
            address(OZ),
            abi.encodeWithSelector(OZ.getInternalSupplyRate.selector),
            abi.encode(netTotal)
        );    
    }


    function _constructUniParams(
        uint amountIn_,
        address receiver_,
        address tokenIn_,
        address tokenIntermediate_,
        address tokenOut_,
        uint blockStamp_
    ) private pure returns(ISwapRouter.ExactInputParams memory params) {
        uint24 poolFee = 500;
        uint minAmountOut = 0;

        params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(tokenIn_, poolFee, tokenIntermediate_, poolFee, tokenOut_), //500 -> 0.05
            recipient: receiver_,
            deadline: blockStamp_,
            amountIn: amountIn_,
            amountOutMinimum: minAmountOut
        });
    }


    function _mockExactInputUni(Type type_, uint amountIn_) internal returns(uint) {
        address internalAccount = 0x5B0091f49210e7B2A57B03dfE1AB9D08289d9294; //second_owner
        uint sUSDe_USDC_rate = 1097380919046205400;
        uint blockStamp;
        address tokenIntermediate = address(USDT);
        address tokenIn;
        address tokenOut;
        address receiver;
        uint amountOut;

        if (Type.BUY == type_) {
            tokenIn = address(USDC);
            tokenOut = address(sUSDe);
            blockStamp = 1725313631;
            amountOut = (amountIn_ * 1e12).mulDivDown(1e18, sUSDe_USDC_rate);
            receiver = internalAccount;
        } else if (Type.SELL == type_) {
            tokenIn = address(sUSDe);
            tokenOut = address(USDC);
            blockStamp = 1725400031;

            amountOut = amountIn_.mulDivDown(sUSDe_USDC_rate, 1e18);
            receiver = second_owner;
        }
        
        ISwapRouter.ExactInputParams memory params = _constructUniParams(
            amountIn_,
            receiver,
            tokenIn,
            tokenIntermediate,
            tokenOut,
            blockStamp
        );

        vm.mockCall(
            address(swapRouterUni), 
            abi.encodeWithSelector(ISwapRouter.exactInput.selector, params), 
            abi.encode(amountOut)
        );

        deal(address(tokenOut), receiver, amountOut);
        return amountOut;
    }


    function _mockSwapExactTokenForPt(Type type_, uint amountIn_) internal returns(uint) {
        address internalAccount = 0x5B0091f49210e7B2A57B03dfE1AB9D08289d9294;
        uint sUSDe_PT_rate = 1106142168328746500;
        uint minPTout = 0;
        uint amountOut;

        if (type_ == Type.BUY) {
            amountOut = amountIn_.mulDivDown(sUSDe_PT_rate, 1e18);

            vm.mockCall(
                address(pendleRouter),
                abi.encodeWithSelector(
                    pendleRouter.swapExactTokenForPt.selector, 
                    internalAccount,
                    address(sUSDeMarket),
                    minPTout,
                    defaultApprox,
                    address(sUSDe).createTokenInputStruct(amountIn_, emptySwap),
                    emptyLimit
                ),
                abi.encode(amountOut, 0, 0)
            );

            deal(address(sUSDe_PT_26SEP), internalAccount, amountOut);
        } else if (type_ == Type.SELL) {
            uint scalingFactor = ozUSDC.scalingFactor();
            uint underlyingAmount = amountIn_.mulDivUp(1e18, scalingFactor);
            uint userShares = ozUSDC.convertToShares(underlyingAmount);

            uint totalUserPT = sUSDe_PT_26SEP.balanceOf(internalAccount);

            uint totalUserUnderlyingAmount = ozUSDC.balanceOf(second_owner).mulDivUp(1e18, scalingFactor);
            uint totalUserShares = ozUSDC.convertToShares(totalUserUnderlyingAmount);

            uint amountInPT = userShares.mulDivDown(totalUserPT, totalUserShares);
            uint minTokenOut = 0;

            amountOut = amountInPT.mulDivDown(1e18, _addFixedAPY(sUSDe_PT_rate, 24 hours, false)); //rateWithFixedAPY

            vm.mockCall(
                address(pendleRouter),
                abi.encodeWithSelector(
                    pendleRouter.swapExactPtForToken.selector, 
                    internalAccount,
                    address(sUSDeMarket),
                    amountInPT,
                    address(sUSDe).createTokenOutputStruct(minTokenOut, emptySwap),
                    emptyLimit
                ),
                abi.encode(amountOut, 0, 0)
            );

            deal(address(sUSDe), internalAccount, amountOut);
        }

        return amountOut;
    }

    //Mocks the buy/sell of PT for backing up ozUSD and/or rebasing rewards
    function _mockPTswap(Type type_, uint amountIn_) internal {
        if (type_ == Type.BUY) {
            uint amountOutsUSDe = _mockExactInputUni(type_, amountIn_);
            _mockSwapExactTokenForPt(type_, amountOutsUSDe);
        } else if (type_ == Type.SELL) {
            uint amountOut = _mockSwapExactTokenForPt(Type.SELL, amountIn_);
            _mockExactInputUni(Type.SELL, amountOut);
        }
    }

    function _addFixedAPY(uint ptPrice_, uint amountTime_, bool isSum_) internal view returns(uint) {
        (, uint pendleFixedAPY) = OZ.getSupplyRates(address(0), false);
        uint growthRateTime = amountTime_.mulDivDown(pendleFixedAPY, 365 days);
        int netGrowth = int((ptPrice_ * growthRateTime + 1e18 / 2) / 1e18);
        netGrowth = isSum_ ? netGrowth : -netGrowth;
        uint netTotal = uint(int(ptPrice_) + netGrowth); 

        return netTotal;
    }


}