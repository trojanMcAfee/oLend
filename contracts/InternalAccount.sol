// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import "forge-std/console.sol";


contract InternalAccount {

    function depositInAave() public payable {
        IWrappedTokenGatewayV3 aaveGW = IWrappedTokenGatewayV3(0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9);
        address aavePool = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;

        aaveGW.depositETH{value: msg.value}(aavePool, msg.sender, 0);

        console.log('msg.sender - ozDiamond: ', msg.sender);
    }

    function delegateCredit() public {


    }

}