// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {IERC20} from "../lib/forge-std/src/interfaces/IERC20.sol";
import {StructGen} from "./StructGen.sol";


contract StateVars is StructGen {

    address public constant router = 0x888888888889758F76e7103c6CbF23ABbF58F946;
    address public constant pendleMarket = 0xd1D7D99764f8a52Aff007b7831cc02748b2013b5;
    IERC20 public constant sUSDe = IERC20(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);

}