// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";



struct AppStorage {
    //Aave 
    IWrappedTokenGatewayV3 aaveGW;
    IPoolAddressesProvider aavePoolProvider;
    uint VARIABLE_RATE;

    //Pendle
    IPAllActionV3 pendleRouter;
    IPMarket sUSDeMarket;

    //ERC20s
    IERC20 aWETH;
    IERC20 USDC;
    IERC20 sUSDe;


}

struct AaveConfig {
    address aaveGW;
    address aavePoolProvider;
}

struct ERC20s {
    address aWETH;
    address USDC;
    address sUSDe; //not used so far
}

struct PendleConfig {
    address pendleRouter;
    address sUSDeMarket;
}