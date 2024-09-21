// SPDX-License-Identifier: UNLICENSED
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
import {IPool as IPoolBal, IVault} from "./interfaces/IBalancer.sol";


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
    IPoolBal balancerPoolWstETHsUSDe;
    IVault balancerVault;
    IPoolBal balancerPool_wstETHWETH;

    //ERC20s and ERC4626
    IERC20 aWETH;
    IERC20 USDC;
    IERC20 USDT;
    IERC20 ozUSD; //proxy
    IERC20 pendlePT; //sUSDe_PT_26SEP
    IERC20 aaveVariableDebtUSDC;
    IERC20 USDe;
    IERC20 wstETH;
    IERC4626 sUSDe;

    //System config
    address OZ;
    uint[] openOrders;
    // mapping(address user => address account) internalAccounts
    mapping(address user => InternalAccount account) internalAccounts;
    // uint accountSequence; //<-- used in _createUser()
    ozRelayer relayer;

}

struct SysConfig {
    address OZ; 
    address relayer;
}

struct AaveConfig {
    address aaveGW;
    address aavePoolProvider;
}

struct BalancerConfig {
    address balancerPoolWstETHsUSDe;
    address balancerVault;
    address balancerPool_wstETHWETH;
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