// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


// import {AppStorage} from "../AppStorage.sol";
import {State} from "../State.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {ICrvMetaRegistry} from "../interfaces/ICurve.sol";


contract ozModifiers is State {
    
    modifier checkAavePool {
        if (s.aavePoolProvider.getPool() != address(s.aavePool)) {
            s.aavePool = IPool(s.aavePoolProvider.getPool());
        }
        _;
    }

    modifier checkCrvMetaRegistry { //not used so far
        if (address(s.curveMetaRegistry) != s.curveAddressProvider.get_address(7)) {
            s.curveMetaRegistry = ICrvMetaRegistry(s.curveAddressProvider.get_address(7));
        }
        _;
    }

}