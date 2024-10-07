// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "../CoreMethods.sol";
import {UserAccountData} from "../../../contracts/AppStorage.sol";

import "forge-std/console.sol";

contract SupplyTest is CoreMethods {

    event NewAccountDataState(
        uint totalCollateralBase,
        uint16 ltv,
        uint currentLiquidationThreshold,
        uint healthFactor
    );

    function test_supply_USDC() public {
        //Pre-conditions
        uint amountIn = USDC.balanceOf(second_owner);
        uint balanceOzUSDC = ozUSDC.balanceOf(second_owner);

        assertTrue(amountIn > 0, 'custom: amountIn 0');
        assertTrue(balanceOzUSDC == 0, 'custom: balanceOzUSDC not 0');
        
        //Actions
        vm.startPrank(second_owner);
        USDC.approve(address(OZ), amountIn);

        vm.expectEmit(false, false, false, true);
        emit NewAccountDataState(
            amountIn,
            ltvStable,
            liqThresholdStable,
            type(uint).max
        );

        uint amountOutPT = OZ.lend(amountIn, address(USDC));

        //Post-conditions
        assertTrue(ozUSDC.balanceOf(second_owner) == amountIn, 'custom: ozUSDC bal no match');
        assertTrue(USDC.balanceOf(second_owner) == 0, 'custom: USDC bal not 0');
        assertTrue(amountOutPT > 0, 'custom: amountOutPT is 0');


        // UserAccountData memory userData = OZ.getUserAccountData(second_owner);

        // console.log('internalAccount: ', userData.internalAccount);
        // console.log('totalCollateralBase: ', userData.totalCollateralBase);
        // console.log('totalDebtBase: ', userData.totalDebtBase);
        // console.log('availableBorrowsBase: ', userData.availableBorrowsBase);
        // console.log('currentLiquidationThreshold: ', userData.currentLiquidationThreshold);
        // console.log('ltv: ', uint(userData.ltv));
        // console.log('healthFactor: ', userData.healthFactor);
    }

}