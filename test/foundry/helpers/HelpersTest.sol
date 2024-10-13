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


    function _mockSwapExactTokenForPt(uint amountIn_) internal {
        address internalAccount = 0x5B0091f49210e7B2A57B03dfE1AB9D08289d9294;
        uint sUSDe_PT_rate = 1106142168328746500;
        uint minPTout = 0;

        uint amountOut = amountIn_.mulDivDown(sUSDe_PT_rate, 1e18);

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
    }


    //Mocks the buy/sell of PT for backing up ozUSD and/or rebasing rewards
    function _mockPTswap(Type type_, uint amountIn_) internal {
        uint amountOutsUSDe = _mockExactInputUni(Type.BUY, amountIn_);
        _mockSwapExactTokenForPt(amountOutsUSDe);
    }


}