// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import {Test} from "../lib/forge-std/src/Test.sol";
import {IERC20} from "./interfaces/IERC20.sol";
// import {StructGen} from "./StructGen.sol";
// import {AppStorageTest} from "../test/foundry/AppStorageTest.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";

import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import {DiamondCutFacet} from "../contracts/facets/DiamondCutFacet.sol";
import {ozLoupe} from "../contracts/facets/ozLoupe.sol";
import {OwnershipFacet} from "../contracts/facets/OwnershipFacet.sol";
import {ozMinter} from "../contracts/facets/ozMinter.sol";
import {Diamond} from "./Diamond.sol";
import {DiamondInit} from "./upgradeInitializers/DiamondInit.sol";
import {ozIDiamond} from "../contracts/interfaces/ozIDiamond.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ozUSDtoken} from "./ozUSDtoken.sol";
import {ozRelayer} from "./ozRelayer.sol";
import {ozOracle} from "../contracts/facets/ozOracle.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol"; 
import {IPool as IPoolBal, IVault} from "../contracts/interfaces/IBalancer.sol";  
import {ozIUSD} from "../contracts/interfaces/ozIUSD.sol";   
import {ozIERC20} from "../contracts/interfaces/ozIERC20.sol";   
import {ICrvRouter, ICrvAddressProvider, IPoolCrv} from "../contracts/interfaces/ICurve.sol";   
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";
import {IPoolAddressesProvider} from "@aave/core-v3/contracts/interfaces/IPoolAddressesProvider.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {console} from "../lib/forge-std/src/Test.sol";

//move this contracto test/foundry
abstract contract StateVars is Test {

    uint public immutable currentBlock = 20665666; //20665666 - 20779705 (recent)
    address public immutable owner = makeAddr('owner');
    address public immutable second_owner = makeAddr('second_owner');
    address public immutable thirdOwner = makeAddr('thirdOwner');

    //Pendle
    IPAllActionV3 public constant pendleRouter = IPAllActionV3(0x888888888889758F76e7103c6CbF23ABbF58F946);
    IPMarket public constant sUSDeMarket = IPMarket(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);
    uint32 twapDuration = 15; //secs
    uint16 ptDiscount = 500; //5%

    //Aave
    IWrappedTokenGatewayV3 public constant aaveGW = IWrappedTokenGatewayV3(0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9);
    IPoolAddressesProvider public constant aavePoolProvider = IPoolAddressesProvider(0x2f39d218133AFaB8F2B819B1066c7E434Ad94E9e);
    IPool public constant aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2); 
    ICreditDelegationToken public constant aaveVariableDebtUSDCDelegate = ICreditDelegationToken(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
    IERC20 public constant aaveVariableDebtUSDC = IERC20(0x72E95b8931767C79bA4EeE721354d6E99a61D004);

    //Balancer
    IPoolBal public constant balancerPool_wstETHsUSDe = IPoolBal(0xa8210885430aaA333c9F0D66AB5d0c312beD5E43);
    IPoolBal public constant balancerPool_wstETHWETH = IPoolBal(0x93d199263632a4EF4Bb438F1feB99e57b4b5f0BD);
    IVault public constant balancerVault = IVault(0xBA12222222228d8Ba445958a75a0704d566BF2C8);

    //Curve
    ICrvRouter curveRouter = ICrvRouter(0x16C6521Dff6baB339122a0FE25a9116693265353);
    ICrvAddressProvider curveAddressProvider = ICrvAddressProvider(0x5ffe7FB82894076ECB99A30D6A32e969e6e35E98);
    IPoolCrv curvePool_sUSDesDAI = IPoolCrv(0x167478921b907422F8E88B43C4Af2B8BEa278d3A);
    IPoolCrv curvePool_sDAIFRAX = IPoolCrv(0xcE6431D21E3fb1036CE9973a3312368ED96F5CE7);
    IPoolCrv curvePool_FRAXUSDC = IPoolCrv(0xDcEF968d416a41Cdac0ED8702fAC8128A64241A2);
    IPoolCrv curvePool_USDCETHWBTC = IPoolCrv(0x7F86Bf177Dd4F3494b841a37e810A34dD56c829B);
    IPoolCrv curvePool_FRAXUSDe = IPoolCrv(0x5dc1BF6f1e983C0b21EfB003c105133736fA0743);

    //Uniswap
    ISwapRouter swapRouterUni = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);

    //ERC20s
    IERC20 public constant USDe = IERC20(0x4c9EDD5852cd905f086C759E8383e09bff1E68B3);
    IERC20 public constant sUSDe = IERC20(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    IERC20 public constant sUSDe_PT_26SEP = IERC20(0x6c9f097e044506712B58EAC670c9a5fd4BCceF13);
    IERC20 public constant YT = IERC20(0xdc02b77a3986da62C7A78FED73949C9767850809);
    IERC20 public constant aWETH = IERC20(0x4d5F47FA6A74757f35C14fD3a6Ef8E3C9BC514E8);
    address public constant USDCaddr = 0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48;
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant aUSDC = IERC20(0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c);
    address public constant USDTaddr = 0xdAC17F958D2ee523a2206206994597C13D831ec7;
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IERC20 public constant wstETH = IERC20(0x7f39C581F595B53c5cb19bD0b3f8dA6c935E2Ca0);
    IERC20 public constant WETH = IERC20(0xC02aaA39b223FE8D0A0e5C4F27eAD9083C756Cc2);
    IERC20 public constant sDAI = IERC20(0x83F20F44975D03b1b09e64809B757c47f942BEeA);
    IERC20 public constant FRAX = IERC20(0x853d955aCEf822Db058eb8505911ED77F175b99e);
    IERC20 public constant WBTC = IERC20(0x2260FAC5E5542a773Aa44fBCfeDf7C193bc2C599);

    //ozTokens
    ozIERC20 ozUSDC;

    //Diamond
    DiamondCutFacet cut;
    ozLoupe loupe;
    OwnershipFacet ownership;
    Diamond ozDiamond;
    ozIDiamond OZ;
    DiamondInit initDiamond;
    ozMinter minter;
    ozOracle oracle;

    //ozUSDtoken
    ERC1967Proxy ozUSDproxy;
    ozUSDtoken ozUSDimpl;
    ozIUSD ozUSD; 
    
    //System
    ozRelayer relayer;
    uint8 oracleRisk = 1; //0.01%

    //For testing purposes only
    address ETH = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    //Interest Rate models
    uint16 ltvStable = 7500;
    uint16 liqThresholdStable = 7800;
}