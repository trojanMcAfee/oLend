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

        uint balanceOwnerOzUSDC_preRebase = ozUSDC.balanceOf(second_owner);
        assertTrue(balanceOwnerOzUSDC_preRebase == amountIn, 'custom: ozUSDC and amountIn diff');

        uint supplyRate_preRebase = OZ.getInternalSupplyRate();

        //Actions
        _advanceInTime(24 hours);
        ozUSDC.rebase();

        //Post-conditions
        uint supplyRate_postRebase = OZ.getInternalSupplyRate();

        uint rateGrowth = ((supplyRate_postRebase - supplyRate_preRebase) * 100) * 1e18 / supplyRate_preRebase;
        uint balanceOwnerOzUSDC_postRebase = ozUSDC.balanceOf(second_owner);
        uint balanceGrowth = ((balanceOwnerOzUSDC_postRebase - balanceOwnerOzUSDC_preRebase) * 100) * 1e18 / balanceOwnerOzUSDC_preRebase;

        assertTrue(balanceGrowth / 1e10 == rateGrowth / 1e10, 'custom: balance and rate diff');
        assertTrue(balanceOwnerOzUSDC_postRebase > balanceOwnerOzUSDC_preRebase, 'custom: no gain rebase');
        
        /**
         * This check proves that the protocol is solvent by giving less to users, in balances, in
         * comparison to the actual growth rate of the backing asset (PT). 
         */
        assertTrue(rateGrowth > balanceGrowth, 'custom: balance higher than rate');
    }


    function test_supply_rebase_redemption_USDC() public {


        //<---- continue here ***
    }

}