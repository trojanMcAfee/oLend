// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {AppStorage} from "./AppStorage.sol";
import {StructGen} from "./StructGen.sol";


contract Modifiers is StructGen {

    // AppStorage internal s;

    
    modifier checkAavePool() {
        if (s.aavePoolProvider.getPool() != s.aavePool) {
            s.aavePool = s.aavePoolProvider.getPool();
        }
        _;
    }

}