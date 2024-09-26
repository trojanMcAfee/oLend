// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "./interfaces/IERC20.sol";
// import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPAllActionV3, SwapData, LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {InternalAccount} from "./InternalAccount.sol";
import {ozRelayer} from "./ozRelayer.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {IERC4626} from "../lib/forge-std/src/interfaces/IERC4626.sol";
import {IPool as IPoolBal, IVault, IAsset} from "./interfaces/IBalancer.sol";
import {ICrvRouter, ICrvAddressProvider, ICrvMetaRegistry, IPoolCrv} from "./interfaces/ICurve.sol";


struct AppStorage {
    //Aave 
    IWrappedTokenGatewayV3 aaveGW;
    IPoolAddressesProvider aavePoolProvider;
    IPool aavePool;
    uint VARIABLE_RATE;

    //Pendle
    IPAllActionV3 pendleRouter;
    IPMarket sUSDeMarket;
    SwapData emptySwap;
    LimitOrderData emptyLimit;
    ApproxParams defaultApprox;
    uint32 twapDuration;
    uint ptDiscount;

    //Balancer
    IPoolBal balancerPool_wstETHsUSDe;
    IVault balancerVault;
    IPoolBal balancerPool_wstETHWETH;

    //Curve
    ICrvRouter curveRouter;
    ICrvAddressProvider curveAddressProvider;
    ICrvMetaRegistry curveMetaRegistry;
    IPoolCrv curvePool_sUSDesDAI;
    IPoolCrv curvePool_sDAIFRAX;
    IPoolCrv curvePool_FRAXUSDC;
    IPoolCrv curvePool_USDCETHWBTC;

    //ERC20s
    IERC20 aWETH;
    IERC20 USDC;
    IERC20 USDT;
    IERC20 ozUSD; //proxy
    IERC20 pendlePT; //sUSDe_PT_26SEP
    IERC20 aaveVariableDebtUSDC;
    IERC20 USDe;
    IERC20 wstETH;
    IERC20 WETH;
    IERC20 sDAI;
    IERC20 FRAX;
    IERC20 WBTC;

    //ERC4626s
    IERC4626 sUSDe;


    //System config
    address OZ;
    address ETH;
    uint[] openOrders;
    // mapping(address user => address account) internalAccounts
    mapping(address user => InternalAccount account) internalAccounts;
    // uint accountSequence; //<-- used in _createUser()
    ozRelayer relayer;

}

struct SysConfig {
    address OZ; 
    address relayer;
    address ETH;
}

struct AaveConfig {
    address aaveGW;
    address aavePoolProvider;
}

struct BalancerConfig {
    address balancerPool_wstETHsUSDe;
    address balancerVault;
    address balancerPool_wstETHWETH;
}

struct CurveConfig {
    address curveRouter;
    address curveAddressProvider;
    address curvePool_sUSDesDAI;
    address curvePool_sDAIFRAX;
    address curvePool_FRAXUSDC;
    address curvePool_USDCETHWBTC;
}

struct ERC20s {
    address aWETH;
    address USDC;
    address sUSDe; 
    address USDT;
    address ozUSDtoken;
    address pendlePT; //sUSDe_PT
    address aaveVariableDebtUSDC;
    address USDe; //not used
    address wstETH;
    address WETH;
    address sDAI;
    address FRAX;
    address WBTC;
}

struct PendleConfig {
    address pendleRouter;
    address sUSDeMarket;
    uint32 twapDuration;
    uint16 ptDiscount;
}

struct UserAccountData {
    uint totalCollateralBase;
    uint totalDebtBase;
    uint availableBorrowsBase;
    uint currentLiquidationThreshold;
    uint ltv;
    uint healthFactor;
}

struct BalancerSwapConfig {
    IVault.SingleSwap singleSwap;
    IVault.BatchSwapStep[] multiSwap;
    IVault.SwapKind batchType;
    IAsset[] assets;
    int[] limits;
    uint limit;
}

enum Tokens {
    WETH,
    ETH,
    USDe,
    USDC,
    PT,
    sDAI,
    FRAX,
    WBTC
}

enum CrvPoolType {
    NULL,
    STABLE,
    TWO_COIN,
    TRICRYPTO
}