// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {AppStorage} from "./AppStorage.sol";
import {StructGen} from "./StructGen.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";


contract Modifiers is StructGen {

    // AppStorage internal s;

    
    modifier checkAavePool() {
        if (s.aavePoolProvider.getPool() != address(s.aavePool)) {
            s.aavePool = IPool(s.aavePoolProvider.getPool());
        }
        _;
    }

}