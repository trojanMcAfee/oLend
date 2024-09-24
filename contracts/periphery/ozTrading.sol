// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {BalancerSwapConfig, CrvPoolType} from "../AppStorage.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {IVault, IAsset} from "../interfaces/IBalancer.sol";
import {IPoolCrv} from "../interfaces/ICurve.sol";
import {HelpersLib} from "../libraries/HelpersLib.sol";
import {ozModifiers} from "./ozModifiers.sol";

import "forge-std/console.sol";


abstract contract ozTrading is ozModifiers {

    using HelpersLib for *;


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


    function _createCrvSwap(address tokenOut_) internal view returns(
        address[11] memory route,
        uint[5][5] memory swap_params,
        address[5] memory pools
    ) {
        address[] memory cacheAddr;
        uint[][] memory cacheUint;

        if (tokenOut_ == address(s.sDAI)) {
            cacheAddr = new address[](11);
            cacheAddr[0] = address(s.sUSDe);
            cacheAddr[1] = address(s.curvePool_sUSDesDAI);
            cacheAddr[2] = address(s.sDAI);
            route = cacheAddr.completeZeroAddr();

            cacheUint = new uint[][](5);
            cacheUint[0] = _createCrvSwapParams(s.curvePool_sUSDesDAI, address(s.sUSDe), address(s.sDAI));
            swap_params = cacheUint.completeZeroUint();

            // swap_params = [
            //     _createCrvSwapParams(s.curvePool_sUSDesDAI, address(s.sUSDe), address(s.sDAI)),
            //     [uint(0),uint(0),uint(0),uint(0),uint(0)],
            //     [uint(0),uint(0),uint(0),uint(0),uint(0)],
            //     [uint(0),uint(0),uint(0),uint(0),uint(0)],
            //     [uint(0),uint(0),uint(0),uint(0),uint(0)]
            // ];
        }

        // route = [
        //     address(s.USDe),
        //     address(s.curvePool_sUSDesDAI),
        //     address(s.sDAI),
        //     address(s.curvePool_sDAIFRAX),
        //     address(s.FRAX),
        //     address(s.curvePool_FRAXUSDC),
        //     address(s.USDC),
        //     address(s.curvePool_USDCETHWBTC),
        //     address(s.WETH),
        //     address(0),
        //     address(0) //<--- see if i can delete these and it still works
        // ]; 

        // swap_params = [ 
        //     _createCrvSwapParams(s.curvePool_sUSDesDAI, address(s.sUSDe), address(s.sDAI)),
        //     _createCrvSwapParams(s.curvePool_sDAIFRAX, address(s.sDAI), address(s.FRAX)),
        //     _createCrvSwapParams(s.curvePool_FRAXUSDC, address(s.FRAX), address(s.USDC)),
        //     _createCrvSwapParams(s.curvePool_USDCETHWBTC, address(s.FRAX), address(s.WETH)),
        //     [uint(0),uint(0),uint(0),uint(0),uint(0)]
        // ];

        pools;
    }


    function _createCrvSwapParams(
        IPoolCrv pool_,
        address tokenIn_,
        address tokenOut_
    ) private view returns(uint[5] memory params) { 
        console.logUint(3);

        bool exepFRAXUSDC = address(pool_) == address(s.curvePool_FRAXUSDC);

        if (exepFRAXUSDC || pool_.N_COINS() == 2) {
            console.logUint(4);

            if (pool_.coins(0) == tokenIn_) {
                params[0] = uint(0);
                params[1] = uint(1);
            } else {
                params[0] = uint(1);
                params[1] = uint(0);
            }
        } else if (pool_.N_COINS() == 3) {
            console.logUint(5);

            if (pool_.coins(0) == tokenIn_) {
                params[0] = uint(0);
            } else if (pool_.coins(1) == tokenIn_) {
                params[0] = uint(1);
            } else if (pool_.coins(2) == tokenIn_) {
                params[0] = uint(2);
            }

            console.logUint(6);

            if (pool_.coins(0) == tokenOut_) {
                params[1] = uint(0);
            } else if (pool_.coins(1) == tokenOut_) {
                params[1] = uint(1);
            } else if (pool_.coins(2) == tokenOut_) {
                params[1] = uint(2);
            }

            console.logUint(7);
        }

        params[2] = uint(1);

        if (tokenIn_ == address(s.sUSDe) || tokenIn_ == address(s.FRAX)) {
            params[3] = uint(CrvPoolType.STABLE); //could be TWO_COIN for sUSDe-sDAI
        } else if (tokenIn_ == address(s.sDAI)) {
            params[3] = uint(CrvPoolType.TWO_COIN);
        } else if (tokenIn_ == address(s.USDC)) {
            params[3] = uint(CrvPoolType.TRICRYPTO);
        }

        console.logUint(8);

        params[4] = exepFRAXUSDC ? 2 : pool_.N_COINS();

        console.logUint(9);
        

    }

}