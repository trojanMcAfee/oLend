// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {AppStorage} from "../AppStorage.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import {console} from "../../lib/forge-std/src/Test.sol";


contract ozMinter {

    AppStorage private s;

    function lend(bool isETH_) external payable {
        address aavePool = s.aavePoolProvider.getPool();
        
        if (isETH_) {
            s.aaveGW.depositETH{value: msg.value}(aavePool, address(this), 0);
            return;
        }
    }

    function borrow(uint amount_) external {
        address aavePool = s.aavePoolProvider.getPool();

        IPool(aavePool).borrow(address(s.USDC), amount_, s.VARIABLE_RATE, 0, address(this));
    }


}