// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {StateVars} from "../../../contracts/StateVars.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import 


contract HelpersTest is StateVars {

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


    function _mockExactInput(SwapUni memory swap_, uint amountIn_) internal {
        ISwapRouter.ExactInputParams memory params = _constructUniParams(
            amountIn_,
            receiver,
            swap_.tokenIn,
            swap_.tokenInt,
            swap_.tokenOut
        );

        // vm.mockCall(
        //     swapRouterUni, 
        //     abi.encodeWithSelector(ISwapRouter.swapRouterUni.selector, params);, 
        //     returnData
        // );


    }


}