// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "../CoreMethods.sol";
import {UserAccountData} from "../../../contracts/AppStorage.sol";

import "forge-std/console.sol";

interface MyRebase {
    function rebase() external;
}

contract SupplyTest is CoreMethods {

    event NewAccountDataState(
        uint totalCollateralBase,
        uint16 ltv,
        uint currentLiquidationThreshold,
        uint healthFactor
    );


    /**
     * Tests that 
     */
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
        vm.stopPrank();

        //Post-conditions
        address intAcc = OZ.getUserAccountData(second_owner).internalAccount;

        assertTrue(ozUSDC.balanceOf(second_owner) == amountIn, 'custom: ozUSDC bal no match');
        assertTrue(USDC.balanceOf(second_owner) == 0, 'custom: USDC bal not 0');
        assertTrue(amountOutPT > 0, 'custom: amountOutPT is 0');
        assertTrue(amountOutPT == sUSDe_PT_26SEP.balanceOf(intAcc), 'custom: PTs dont match');
    }


    function test_supply_and_rebase_USDC() public {
        //Pre-conditions
        uint amountIn = USDC.balanceOf(second_owner);
        assertTrue(amountIn > 0, 'custom: amountIn is 0');

        vm.startPrank(second_owner);
        USDC.approve(address(OZ), amountIn);
        OZ.lend(amountIn, address(USDC));
        vm.stopPrank();

        uint balanceOwnerOzUSDC = ozUSDC.balanceOf(second_owner);
        console.log('balanceOwnerOzUSDC - pre rebase: ', balanceOwnerOzUSDC);
        console.log('amountIn: ', amountIn);

        //Actions
        _advanceInTime(24 hours);
        MyRebase(address(ozUSDC)).rebase();

        //Post-conditions
        balanceOwnerOzUSDC = ozUSDC.balanceOf(second_owner);
        console.log('balanceOwnerOzUSDC - post rebase: ', balanceOwnerOzUSDC);


    


    }

}