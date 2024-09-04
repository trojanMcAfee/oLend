// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {AppStorage} from "../AppStorage.sol";
// import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import {console} from "../../lib/forge-std/src/Test.sol";


contract ozMinter {

    AppStorage private s;

    function mintOzUSD() public payable returns(uint) {
        address aavePool = s.aavePoolProvider.getPool();
        
        s.aaveGW.depositETH{value: msg.value}(aavePool, address(this), 0);

    



        return 3;
    }

}