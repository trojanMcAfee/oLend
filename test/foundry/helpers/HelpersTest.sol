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

        // (, uint pendleFixedAPY) = OZ.getSupplyRates(address(0), false);
        // uint growthRateTime = amountTime_.mulDivDown(pendleFixedAPY, 365 days);
        // uint ptPrice = OZ.getInternalSupplyRate();
        // uint netGrowth = (ptPrice * growthRateTime + 1e18 / 2) / 1e18;
        // uint netTotal = ptPrice + netGrowth;
        
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
        address tokenOut_
    ) private pure returns(ISwapRouter.ExactInputParams memory params) {
        uint24 poolFee = 500;
        uint minAmountOut = 0;
        uint blockStamp = 1725313631;

        params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(tokenIn_, poolFee, tokenIntermediate_, poolFee, tokenOut_), //500 -> 0.05
            recipient: receiver_,
            deadline: blockStamp,
            amountIn: amountIn_,
            amountOutMinimum: minAmountOut
        });
    }


    function _mockExactInputUni(Type buy_, uint amountIn_) internal returns(uint) {
        uint amountOut;
        address tokenIn;
        address tokenIntermediate;
        address tokenOut;
        address receiver;

        if (Type.BUY == buy_) {
            tokenIn = address(USDC);
            tokenIntermediate = address(USDT);
            tokenOut = address(sUSDe);

            uint sUSDe_USDC_rate = 1097380919046205400;
            address internalAccount = 0x5B0091f49210e7B2A57B03dfE1AB9D08289d9294; //second_owner
            receiver = internalAccount;
            amountOut = (amountIn_ * 1e12).mulDivDown(1e18, sUSDe_USDC_rate);
        }
        
        ISwapRouter.ExactInputParams memory params = _constructUniParams(
            amountIn_,
            receiver,
            tokenIn,
            tokenIntermediate,
            tokenOut
        );

        vm.mockCall(
            address(swapRouterUni), 
            abi.encodeWithSelector(ISwapRouter.exactInput.selector, params), 
            abi.encode(amountOut)
        );

        deal(address(sUSDe), receiver, amountOut);
        return amountOut;
    }


    function _mockSwapExactTokenForPt(Type type_, uint amountIn_) internal {
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
    }

    //Mocks the buy/sell of PT for backing up ozUSD and/or rebasing rewards
    function _mockPTswap(Type type_, uint amountIn_) internal {
        uint amountOutsUSDe = _mockExactInputUni(type_, amountIn_);
        _mockSwapExactTokenForPt(type_, amountOutsUSDe);
    }

    function _addFixedAPY(uint ptPrice_, uint amountTime_, bool isSum_) internal returns(uint) {
        (, uint pendleFixedAPY) = OZ.getSupplyRates(address(0), false);
        uint growthRateTime = amountTime_.mulDivDown(pendleFixedAPY, 365 days);
        int netGrowth = int((ptPrice_ * growthRateTime + 1e18 / 2) / 1e18);
        netGrowth = isSum_ ? netGrowth : -netGrowth;
        uint netTotal = uint(int(ptPrice_) + netGrowth); 

        console.log('');
        console.log('--- in _addFixedAPY() ---');
        console.log('pendleFixedAPY: ', pendleFixedAPY);
        console.log('ptPrice_: ', ptPrice_);
        console.log('growthRateTime: ', growthRateTime);
        console.log('netGrowth: ', netGrowth);
        console.log('netTotal: ', netTotal);
        console.log('');

        return netTotal;
    }


}