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
import {AppStorage, AaveConfig, ERC20s, PendleConfig} from "../AppStorage.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";

import {console} from "../../lib/forge-std/src/Test.sol";


contract DiamondInit {    

    AppStorage private s;

    
    function init(
        AaveConfig memory aave_, 
        ERC20s memory tokens_,
        PendleConfig memory pendle_
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

        //Pendle
        s.pendleRouter = IPAllActionV3(pendle_.pendleRouter);
        s.sUSDeMarket = IPMarket(pendle_.sUSDeMarket);
        s.defaultApprox = ApproxParams(0, type(uint256).max, 0, 256, 1e14);

        //ERC20s
        s.aWETH = IERC20(tokens_.aWETH);
        s.USDC = IERC20(tokens_.USDC);
        s.sUSDe = IERC20(tokens_.sUSDe);
        s.USDT = IERC20(tokens_.USDT);
        s.ozUSD = IERC20(tokens_.ozUSD);
        s.pendlePT = IERC20(tokens_.pendlePT); //sUSDe_PT




        // add your own state variables 
        // EIP-2535 specifies that the `diamondCut` function takes two optional 
        // arguments: address _init and bytes calldata _calldata
        // These arguments are used to execute an arbitrary function using delegatecall
        // in order to set state variables in the diamond during deployment or an upgrade
        // More info here: https://eips.ethereum.org/EIPS/eip-2535#diamond-interface 
    }


}
