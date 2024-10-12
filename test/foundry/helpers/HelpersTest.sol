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
        address tokenIntermediate_,
        address tokenOut_
    ) private returns(ISwapRouter.ExactInputParams memory params) {
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

        vm.mockCall(
            address(swapRouterUni), 
            abi.encodeWithSelector(ISwapRouter.exactInput.selector, params), 
            abi.encode(amountOut)
        );
    }


}