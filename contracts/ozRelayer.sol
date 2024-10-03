// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IERC20} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPAllActionV3, SwapData, LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {HelpersLib} from "./libraries/HelpersLib.sol";

import "forge-std/console.sol";


contract ozRelayer {

    using SafeERC20 for IERC20;
    using HelpersLib for address;

    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant sUSDe = IERC20(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IPMarket public constant sUSDeMarket = IPMarket(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);
    IPAllActionV3 public constant pendleRouter = IPAllActionV3(0x888888888889758F76e7103c6CbF23ABbF58F946);
    IPool aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

    ApproxParams defaultApprox = ApproxParams(0, type(uint256).max, 0, 256, 1e14);
    SwapData emptySwap;
    LimitOrderData emptyLimit;

    function borrowInternal(uint amount_, address receiver_, address account_) external {
        uint variableRate = 2;

        aavePool.borrow(address(USDC), amount_, variableRate, 0, account_);

        USDC.safeTransfer(msg.sender, amount_);
    }

    function buyPT(uint amountIn_, address intAccount_, address tokenIn_) external returns(uint) {        
        uint sUSDeOut;
        uint minTokenOut = 0;
        
        if (tokenIn_ == address(USDC)) {
            sUSDeOut = _swapUni(
                address(USDC), 
                address(sUSDe), 
                intAccount_, 
                amountIn_, 
                minTokenOut
            );
        }

        sUSDe.approve(address(pendleRouter), sUSDeOut);
        uint minPTout = 0;

        (uint amountOutPT,,) = pendleRouter.swapExactTokenForPt(
            intAccount_, 
            address(sUSDeMarket), 
            minPTout, 
            defaultApprox, //check StructGen.sol for a more gas-efficient impl of this
            address(sUSDe).createTokenInputStruct(sUSDeOut, emptySwap), 
            emptyLimit
        );

        return amountOutPT;
    }


    //-------------
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

}