// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";

import "forge-std/console.sol";


contract InternalAccount {

    function depositInAave() public payable {
        IWrappedTokenGatewayV3 aaveGW = IWrappedTokenGatewayV3(0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9);
        IPool aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

        aaveGW.depositETH{value: msg.value}(address(aavePool), address(this), 0);

        console.log('msg.sender - ozDiamond: ', msg.sender);
        console.log('int acc: ', address(this));
        
        (,,uint availableBorrowsBase,,,) = aavePool.getUserAccountData(msg.sender);
        console.log('availableBorrowsBase - oz - pre delegate: ', availableBorrowsBase);

        (,,uint availableBorrowsBase2,,,) = aavePool.getUserAccountData(address(this));
        console.log('availableBorrowsBase - int acc - pre delegate: ', availableBorrowsBase2);

        console.log('');
        console.log('--- delegate credit ---');
        console.log('');

        //-----------
        ICreditDelegationToken aaveVariableDebtUSDC = ICreditDelegationToken(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
        aaveVariableDebtUSDC.approveDelegation(msg.sender, type(uint).max);
        // this ^ is not approving delegation to OZ <---------

        (,,uint availableBorrowsBase3,,,) = aavePool.getUserAccountData(msg.sender);
        console.log('availableBorrowsBase - oz - post delegate: ', availableBorrowsBase3);

        (,,uint availableBorrowsBase4,,,) = aavePool.getUserAccountData(address(this));
        console.log('availableBorrowsBase - int acc - post delegate: ', availableBorrowsBase4);
    }

    function delegateCredit() public {


    }

}