// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";
import {IERC20} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
// import {ozRelayer} from "./ozRelayer.sol";

import "forge-std/console.sol";


contract InternalAccount {

    address public relayer;

    event FundsDelegated(address indexed internalAccount, uint indexed amount);

    constructor(address relayer_) {
        relayer = relayer_;
    }

    function depositInAave() public payable { //<--- change depositInAave to depositAndDelegatex
        IWrappedTokenGatewayV3 aaveGW = IWrappedTokenGatewayV3(0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9);
        IPool aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

        aaveGW.depositETH{value: msg.value}(address(aavePool), address(this), 0);

        ICreditDelegationToken aaveVariableDebtUSDCDelegate = ICreditDelegationToken(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
        aaveVariableDebtUSDCDelegate.approveDelegation(relayer, type(uint).max);
        
        emit FundsDelegated(address(this), msg.value);
    }

}