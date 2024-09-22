// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


// import {AppStorage} from "../AppStorage.sol";
import {State} from "../State.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";


contract ozModifiers is State {
    
    modifier checkAavePool() {
        if (s.aavePoolProvider.getPool() != address(s.aavePool)) {
            s.aavePool = IPool(s.aavePoolProvider.getPool());
        }
        _;
    }

}