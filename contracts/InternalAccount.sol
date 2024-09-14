// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;



contract InternalAccount {

    function depositInAave() public {
        address aaveGW = 0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9;
        aaveGW.depositETH{value: msg.value}(s.aavePool, msg.sender, 0);
        //^ finish this and this is how you deposit into the system
    }

    function delegateCredit() public {


    }

}