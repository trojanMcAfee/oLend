// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";
import {IERC20} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";

import "forge-std/console.sol";


contract InternalAccount {

    function depositInAave() public payable {
        IWrappedTokenGatewayV3 aaveGW = IWrappedTokenGatewayV3(0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9);
        IPool aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);

        aaveGW.depositETH{value: msg.value}(address(aavePool), address(this), 0);

        console.log('msg.sender - ozDiamond: ', msg.sender);
        console.log('int acc: ', address(this));

        (,,uint availableBorrowsBase2,,,) = aavePool.getUserAccountData(address(this));
        console.log('availableBorrowsBase - int acc - pre delegate: ', availableBorrowsBase2);

        console.log('');
        console.log('--- delegate credit ---');
        console.log('');

        //-----------
        console.log('msg.sender - oz: ', msg.sender);
        address OZ = 0xc7183455a4C133Ae270771860664b6B7ec320bB1;
        ICreditDelegationToken aaveVariableDebtUSDC = ICreditDelegationToken(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
        aaveVariableDebtUSDC.approveDelegation(OZ, type(uint).max);

    }

    function delegateCredit() public {}

    function borrowInternal(uint amount_, address receiver_) external {
        IWrappedTokenGatewayV3 aaveGW = IWrappedTokenGatewayV3(0x893411580e590D62dDBca8a703d61Cc4A8c7b2b9);
        IPool aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
        IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        address OZ = msg.sender;
        console.log('sender in borrowInternal: ', msg.sender);
        uint variableRate = 2;
        address owner = 0x7c8999dC9a822c1f0Df42023113EDB4FDd543266;

        console.log('oz usdc bal - pre borrow: ', USDC.balanceOf(OZ));
        console.log('intAccount usdc bal - pre borrow: ', USDC.balanceOf(address(this)));
        console.log('owner usdc bal - pre borrow: ', USDC.balanceOf(owner));

        // aavePool.borrow(address(USDC), amount_, variableRate, 0, address(this));
        (bool s,) = address(aavePool).delegatecall(
            abi.encodeWithSelector(
                aavePool.borrow.selector, 
                address(USDC), amount_, variableRate, 0, address(this)
            )
        );
        require(s, 'fff');

        console.log('oz usdc bal - post borrow: ', USDC.balanceOf(OZ));
        console.log('intAccount usdc bal - post borrow: ', USDC.balanceOf(address(this)));
        console.log('owner usdc bal - post borrow: ', USDC.balanceOf(owner));
    }


}