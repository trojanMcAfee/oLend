// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";


struct AppStorage {
    //AAVE 
    IWrappedTokenGatewayV3 aaveGW;
    IPoolAddressesProvider aavePoolProvider;


}

struct AaveConfig {
    address aaveGW;
    address aavePoolProvider;
}