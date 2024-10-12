// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {AppStorageTest, SwapUni, Type} from "@test/foundry/AppStorageTest.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
 

contract HelpersTest is AppStorageTest {

    using FixedPointMathLib for *;

    function _constructUniParams(
        uint amountIn_,
        address receiver_,
        address tokenIn_,
        address tokenInt_,
        address tokenOut_
    ) private returns(ISwapRouter.ExactInputParams memory params) {
        uint poolFee = 500;
        uint minAmountOut = 0;

        params = ISwapRouter.ExactInputParams({
            path: abi.encodePacked(tokenIn_, poolFee, tokenIn_, poolFee, tokenOut_), //500 -> 0.05
            recipient: receiver_,
            deadline: block.timestamp,
            amountIn: amountIn_,
            amountOutMinimum: minAmountOut
        });
    }

    //thia is the firs swapUni <-------- ****
    function _mockExactInputUni(Type buy_, address receiver_) internal {
        uint amountIn;
        uint minTokenOut;
        uint amountOut;
        address tokenIn;
        address tokenInt;
        address tokenOut;

        if (Type.BUY == buy_) {
            amountIn = 10000000000;
            tokenIn = address(USDC);
            tokenInt = address(USDT);
            tokenOut = address(sUSDe);
            amountOut = 9112606048127348920058;

            uint sUSDe_USDC_rate = (amountIn * 1e12).mulDivDown(1e18, amountOut);
        }
        
        ISwapRouter.ExactInputParams memory params = _constructUniParams(
            amountIn,
            receiver_,
            tokenIn,
            tokenInt,
            tokenOut
        );

        vm.mockCall(
            address(swapRouterUni), 
            abi.encodeWithSelector(ISwapRouter.exactInput.selector, params), 
            abi.encode(amountOut)
        );


    }


}