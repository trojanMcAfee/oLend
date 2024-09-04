// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";


struct AppStorage {
    //AAVE 
    IWrappedTokenGatewayV3 aaveGW;
    IPoolAddressesProvider aavePoolProvider;

    //ERC20s
    IERC20 aWETH;


}

struct AaveConfig {
    address aaveGW;
    address aavePoolProvider;
}

struct ERC20s {
    address aWETH;
}