// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {Test} from "../lib/forge-std/src/Test.sol";
import {IERC20} from "./interfaces/IERC20.sol";
// import {StructGen} from "./StructGen.sol";
import {StructGenTest} from "../test/foundry/StructGenTest.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";
import {ozMinter} from "../contracts/facets/ozMinter.sol";
import {Diamond} from "./Diamond.sol";
import {DiamondInit} from "./upgradeInitializers/DiamondInit.sol";
import {ozIDiamond} from "../contracts/interfaces/ozIDiamond.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ozUSD} from "./ozUSD.sol";
import {ozRelayer} from "./ozRelayer.sol";
import {ozOracle} from "../contracts/facets/ozOracle.sol";

import {console} from "../lib/forge-std/src/Test.sol";


contract StateVars is StructGenTest, Test {

    uint currentBlock = 20665666; //20665666 - 20779705 (recent)
    address owner = makeAddr('owner');
    address second_owner = makeAddr('second_owner');

    //Pendle
    IPAllActionV3 public constant pendleRouter = IPAllActionV3(0x888888888889758F76e7103c6CbF23ABbF58F946);
    IPMarket public constant sUSDeMarket = IPMarket(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);
    uint32 twapDuration = 15; //secs
    uint16 ptDiscount = 500; //5%

    //Aave
    address public constant aaveGW = 0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9;
    address public constant aavePoolProvider = 0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e;
    IPool public constant aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2); 

    //ERC20s
    IERC20 public constant USDe = IERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    IERC20 public constant sUSDe = IERC20(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    IERC20 public constant sUSDe_PT_26SEP = IERC20(0x6c9f097e044506712B58EAC670c9a5fd4BCceF13);
    IERC20 public constant YT = IERC20(0xdc02b77a3986da62C7A78FED73949C9767850809);
    address public constant aWETHaddr = 0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8;
    address public constant USDCaddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    address public constant aUSDCaddr = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
    address public constant USDTaddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;

    //Diamond
    DiamondCutFacet cut;
    DiamondLoupeFacet loupe;
    OwnershipFacet ownership;
    Diamond ozDiamond;
    ozIDiamond OZ;
    DiamondInit initDiamond;
    ozMinter minter;
    ozOracle oracle;

    //ozUSD
    ERC1967Proxy ozUSDproxy;
    ozUSD ozUSDimpl;
    IERC20 ozUsd; 
    
    //System
    ozRelayer relayer;
}