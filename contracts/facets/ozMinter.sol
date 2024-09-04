// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {AppStorage} from "../AppStorage.sol";


contract ozMinter {

    AppStorage private s;

    function sayHello() public payable returns(uint) {

        // function depositETH(address pool, address onBehalfOf, uint16 referralCode) external payable;
        s.aaveGW.depositETH(ethUSD_pool, msg.sender, 0);
        




        return 3;
    }

}