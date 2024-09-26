// SPDX-License-Identifier: MIT
pragma solidity ^0.8.0;

/******************************************************************************\
* Author: Nick Mudge <nick@perfectabstractions.com> (https://twitter.com/mudgen)
* EIP-2535 Diamonds: https://eips.ethereum.org/EIPS/eip-2535
*
* Implementation of a diamond.
/******************************************************************************/

import {LibDiamond} from "../libraries/LibDiamond.sol";
import { IDiamondLoupe } from "../interfaces/IDiamondLoupe.sol";
import { IDiamondCut } from "../interfaces/IDiamondCut.sol";
import { IERC173 } from "../interfaces/IERC173.sol";
import { IERC165 } from "../interfaces/IERC165.sol";

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {AppStorage, AaveConfig, ERC20s, PendleConfig, SysConfig, BalancerConfig, CurveConfig} from "../AppStorage.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IERC4626} from "../../lib/forge-std/src/interfaces/IERC4626.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {ozRelayer} from "../ozRelayer.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IPool as IPoolBal, IVault} from "../interfaces/IBalancer.sol";
import {ICrvRouter, ICrvAddressProvider, ICrvMetaRegistry, IPoolCrv} from "../interfaces/ICurve.sol";

import {console} from "../../lib/forge-std/src/Test.sol";


contract DiamondInit {    

    AppStorage private s;

    
    function init(
        AaveConfig memory aave_, 
        BalancerConfig memory balancer_,
        PendleConfig memory pendle_,
        CurveConfig memory curve_,
        ERC20s memory tokens_,
        SysConfig memory sys_
    ) external {
        // adding ERC165 data
        LibDiamond.DiamondStorage storage ds = LibDiamond.diamondStorage();
        ds.supportedInterfaces[type(IERC165).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondCut).interfaceId] = true;
        ds.supportedInterfaces[type(IDiamondLoupe).interfaceId] = true;
        ds.supportedInterfaces[type(IERC173).interfaceId] = true;

        //Aave
        s.aaveGW = IWrappedTokenGatewayV3(aave_.aaveGW);
        s.aavePoolProvider = IPoolAddressesProvider(aave_.aavePoolProvider);
        s.VARIABLE_RATE = 2;
        s.aavePool = IPool(s.aavePoolProvider.getPool());

        //Balancer
        s.balancerPool_wstETHsUSDe = IPoolBal(balancer_.balancerPool_wstETHsUSDe);
        s.balancerVault = IVault(balancer_.balancerVault);
        s.balancerPool_wstETHWETH = IPoolBal(balancer_.balancerPool_wstETHWETH);

        //Pendle
        s.pendleRouter = IPAllActionV3(pendle_.pendleRouter);
        s.sUSDeMarket = IPMarket(pendle_.sUSDeMarket);
        s.defaultApprox = ApproxParams(0, type(uint256).max, 0, 256, 1e14);
        s.ptDiscount = pendle_.ptDiscount;
        s.twapDuration = pendle_.twapDuration;

        // struct ApproxParams {
        //     uint256 guessMin;
        //     uint256 guessMax;
        //     uint256 guessOffchain;
        //     uint256 maxIteration;
        //     uint256 eps;
        // }

        //Curve
        s.curveRouter = ICrvRouter(curve_.curveRouter);
        s.curveAddressProvider = ICrvAddressProvider(curve_.curveAddressProvider);
        s.curveMetaRegistry = ICrvMetaRegistry(s.curveAddressProvider.get_address(7));
        s.curvePool_sUSDesDAI = IPoolCrv(curve_.curvePool_sUSDesDAI);
        s.curvePool_sDAIFRAX = IPoolCrv(curve_.curvePool_sDAIFRAX);
        s.curvePool_FRAXUSDC = IPoolCrv(curve_.curvePool_FRAXUSDC);
        s.curvePool_USDCETHWBTC = IPoolCrv(curve_.curvePool_USDCETHWBTC);

        //ERC20s and ERC4626
        s.aWETH = IERC20(tokens_.aWETH);
        s.USDC = IERC20(tokens_.USDC);
        s.USDT = IERC20(tokens_.USDT);
        s.ozUSD = IERC20(tokens_.ozUSDtoken);
        s.pendlePT = IERC20(tokens_.pendlePT); //sUSDe_PT
        s.aaveVariableDebtUSDC = IERC20(tokens_.aaveVariableDebtUSDC);
        s.USDe = IERC20(tokens_.USDe);
        s.wstETH = IERC20(tokens_.wstETH);
        s.WETH = IERC20(tokens_.WETH);
        s.sDAI = IERC20(tokens_.sDAI);
        s.FRAX = IERC20 (tokens_.FRAX);
        s.WBTC = IERC20 (tokens_.WBTC);

        //ERC4626s
        s.sUSDe = IERC4626(tokens_.sUSDe);

        //System config
        s.OZ = sys_.OZ;
        s.relayer = ozRelayer(sys_.relayer);
        s.ETH = sys_.ETH;




        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}
