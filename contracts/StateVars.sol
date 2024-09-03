// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {StructGen} from "./StructGen.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";


contract StateVars is StructGen {

    address public constant ownerPT = 0x62178e35ccef8E00e33AFC95F12a590b40E51E04;
    uint blockOwnerPT = 20468410;

    uint currentBlock = 20665666;

    IPAllActionV3 public constant pendleRouter = IPAllActionV3(0x888888888889758F76e7103c6CbF23ABbF58F946);
    IPMarket public constant sUSDeMarket = IPMarket(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);

    IERC20 public constant sUSDe = IERC20(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    IERC20 public constant sUSDe_PT_26SEP = IERC20(0x6c9f097e044506712B58EAC670c9a5fd4BCceF13);
    IERC20 public constant YT = IERC20(0xdc02b77a3986da62C7A78FED73949C9767850809);
    // "@nomiclabs/hardhat-ethers": "^2.0.2",
    // "@nomiclabs/hardhat-waffle": "^2.0.1",
}