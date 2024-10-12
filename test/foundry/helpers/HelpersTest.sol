// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {AppStorageTest, SwapUni, Type} from "@test/foundry/AppStorageTest.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import "forge-std/console.sol";
 

contract HelpersTest is AppStorageTest {

    using FixedPointMathLib for *;

    function _constructUniParams(
        uint amountIn_,
        address receiver_,
        address tokenIn_,
        address tokenInt_,
        address tokenOut_
    ) private returns(ISwapRouter.ExactInputParams memory params) {
        uint24 poolFee = 500;
        uint minAmountOut = 0;
        uint blockStamp = 1725313631;

        // ISwapRouter.ExactInputParams memory params2 = ISwapRouter.ExactInputParams({
        //     path: abi.encodePacked(tokenIn_, poolFee, tokenIn_, poolFee, tokenOut_), //500 -> 0.05
        //     recipient: receiver_,
        //     deadline: blockStamp,
        //     amountIn: amountIn_,
        //     amountOutMinimum: minAmountOut
        // });

        // console.logBytes(abi.encodePacked(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48, poolFee, 0xdAC17F958D2ee523a2206206994597C13D831ec7, poolFee, 0x9D39A5DE30e57443BfF2A8307A4256c8797A3497));
        // console.log('params3.path ^^^^^^^^^^^^^^^^^');

        params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(tokenIn_, poolFee, tokenInt_, poolFee, tokenOut_), //500 -> 0.05
            recipient: receiver_,
            deadline: blockStamp,
            amountIn: amountIn_,
            amountOutMinimum: minAmountOut
        });

        console.log('');
        console.log('--- in constructUniParams ---');
        console.log('tokenIn_: ', tokenIn_);
        console.log('poolFee: ', poolFee);
        console.log('USDT: ', address(USDT));
        console.log('tokenOut_: ', tokenOut_);
        console.log('receiver_: ', receiver_);
        console.log('block.timestamp: ', block.timestamp);
        console.log('amountIn_: ', amountIn_);
        console.log('minAmountOut: ', minAmountOut);
    }

    //thia is the firs swapUni <-------- ****
    function _mockExactInputUni(Type buy_, address owner_, uint amountIn_) internal {
        uint minTokenOut;
        uint amountOut;
        address tokenIn;
        address tokenInt;
        address tokenOut;
        address receiver;

        if (Type.BUY == buy_) {
            tokenIn = address(USDC);
            tokenInt = address(USDT);
            tokenOut = address(sUSDe);

            uint sUSDe_USDC_rate = 1097380919046205400;
            address intAcc = 0x5B0091f49210e7B2A57B03dfE1AB9D08289d9294;
            receiver = intAcc;
            amountOut = (amountIn_ * 1e12).mulDivDown(1e18, sUSDe_USDC_rate);
        }
        
        ISwapRouter.ExactInputParams memory params = _constructUniParams(
            amountIn_,
            receiver,
            tokenIn,
            tokenInt,
            tokenOut
        );

        console.log('swapRouterUni: ', address(swapRouterUni));
        console.log('');

        console.logBytes(params.path);
        console.log('params: ', params.recipient);
        console.log('params: ', params.deadline);
        console.log('params: ', params.amountIn);
        console.log('params: ', params.amountOutMinimum);

        vm.mockCall(
            address(swapRouterUni), 
            abi.encodeWithSelector(ISwapRouter.exactInput.selector, params), 
            abi.encode(uint(111))
        );
    }


}