// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "./interfaces/IERC20.sol";
// import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPAllActionV3, SwapData, LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";


struct AppStorage {
    //Aave 
    IWrappedTokenGatewayV3 aaveGW;
    IPoolAddressesProvider aavePoolProvider;
    address aavePool;
    uint VARIABLE_RATE;

    //Pendle
    IPAllActionV3 pendleRouter;
    IPMarket sUSDeMarket;
    SwapData emptySwap;
    LimitOrderData emptyLimit;
    ApproxParams defaultApprox;
    uint32 twapDuration;
    uint ptDiscount;

    //ERC20s
    IERC20 aWETH;
    IERC20 USDC;
    IERC20 sUSDe;
    IERC20 USDT;
    IERC20 ozUSD; //proxy
    IERC20 pendlePT; //sUSDe_PT_26SEP

    //System config
    address OZ;
    uint[] openOrders;
    mapping(address user => address account) internalAccounts
    // uint accountSequence; //<-- used in _createUser()

}

struct SysConfig {
    address OZ; 
}

struct AaveConfig {
    address aaveGW;
    address aavePoolProvider;
}

struct ERC20s {
    address aWETH;
    address USDC;
    address sUSDe; //not used so far
    address USDT;
    address ozUSD;
    address pendlePT; //sUSDe_PT
}

struct PendleConfig {
    address pendleRouter;
    address sUSDeMarket;
    uint32 twapDuration;
    uint16 ptDiscount;
}

struct UserAccountData {
    uint totalCollateralBase,
    uint totalDebtBase,
    uint availableBorrowsBase,
    uint currentLiquidationThreshold,
    uint ltv,
    uint healthFactor
}