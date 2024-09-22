// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {BalancerSwapConfig} from "../AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IVault, IAsset} from "../interfaces/IBalancer.sol";
import {HelpersLib} from "../libraries/HelpersLib.sol";
import {ozModifiers} from "./ozModifiers.sol";


abstract contract ozTrading is ozModifiers {

    using HelpersLib for int;


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
                path: abi.encodePacked(tokenIn_, poolFee, address(s.USDT), poolFee, tokenOut_), //500 -> 0.05
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minAmountOut_
            });

        return swapRouterUni.exactInput(params);
    }


    function _swapBalancer( 
        address tokenIn_, 
        address tokenOut_, 
        uint amountIn_,
        uint minAmountOut_,
        bool isMultiHop_
    ) internal returns(uint amountOut) {
        BalancerSwapConfig memory swapConfig;

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false, 
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        if (isMultiHop_) {
            IVault.BatchSwapStep memory firstLeg = _createBatchStep(
                s.balancerPool_wstETHsUSDe.getPoolId(),
                0, 1, amountIn_
            );
            IVault.BatchSwapStep memory secondLeg = _createBatchStep(
                s.balancerPool_wstETHWETH.getPoolId(),
                1, 2, 0
            );

            IVault.BatchSwapStep[] memory swaps = new IVault.BatchSwapStep[](2);
            swaps[0] = firstLeg;
            swaps[1] = secondLeg;
            swapConfig.multiSwap = swaps;

            IAsset[] memory assets = new IAsset[](3);
            assets[0] = IAsset(address(s.sUSDe));
            assets[1] = IAsset(address(s.wstETH));
            assets[2] = IAsset(address(s.WETH));
            swapConfig.assets = assets;

            /**
             * You calculate minOuts with this on this step.
             * Add slippage tolerance to assetDeltas.
             * Do it offchain
             */
            s.balancerVault.queryBatchSwap( //returns(int[] memory assetDeltas)
                IVault.SwapKind.GIVEN_IN,
                swaps,
                assets,
                funds
            );
            /************/

            int[] memory limits = new int[](3); //<---- this is minOut, from above ^ 
            limits[0] = type(int).max;
            limits[2] = type(int).max;

            swapConfig.limits = limits;

            swapConfig.batchType = IVault.SwapKind.GIVEN_IN;
        } else {
            IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
                poolId: s.balancerPool_wstETHsUSDe.getPoolId(),
                kind: IVault.SwapKind.GIVEN_IN,
                assetIn: IAsset(tokenIn_),
                assetOut: IAsset(tokenOut_),
                amount: amountIn_,
                userData: new bytes(0)
            });
        }

        IERC20(tokenIn_).approve(address(s.balancerVault), amountIn_);
        // IERC20(tokenIn_).safeApprove(s.balancerVault, singleSwap.amount); //use this in prod - for safeApprove to work, allowance has to be reset to 0 on a mock. Can't be done on mockCall()
        // amountOut = _executeSwap(singleSwap, funds, minAmountOut_, block.timestamp);
        amountOut = _executeSwap(swapConfig, funds, true);
    }


    function _executeSwap(
        BalancerSwapConfig memory swapConfig_,
        IVault.FundManagement memory funds_,
        bool isMultiHop_
    ) private returns(uint) {
        if (isMultiHop_) {
            int[] memory assetsDeltas = s.balancerVault.batchSwap(
                swapConfig_.batchType,
                swapConfig_.multiSwap, 
                swapConfig_.assets,
                funds_,
                swapConfig_.limits,
                block.timestamp
            );
            
            return assetsDeltas[2].abs();
        }
    }

    //this below needs to be put in this ^ above, especially the error handling 
    // function _executeSwap(
    //     IVault.SingleSwap memory singleSwap_,
    //     IVault.FundManagement memory funds_,
    //     uint minAmountOut_,
    //     uint blockStamp_
    // ) private returns(uint) 
    // {        
    //     try s.balancerVault.swap(singleSwap_, funds_, minAmountOut_, blockStamp_) returns(uint amountOut) {
    //         if (amountOut == 0) revert('my 1');
    //         return amountOut;
    //     } catch Error(string memory reason) {
    //         revert('error in _executeSwap()');
    //         // if (Helpers.compareStrings(reason, 'BAL#507')) {
    //         //     revert('my 2');
    //         // } else {
    //         //     revert(reason);
    //         // }
    //     }
    // }


    function _createBatchStep(
        bytes32 poolId_,
        uint assetInIndex_,
        uint assetOutIndex_,
        uint amount_
    ) private pure returns(IVault.BatchSwapStep memory leg) {
        leg = IVault.BatchSwapStep(poolId_, assetInIndex_, assetOutIndex_, amount_, new bytes(0));
    }

}