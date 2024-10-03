// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "./CoreMethods.sol";
import {UserAccountData} from "../../contracts/AppStorage.sol";


contract LendingFlowTest is CoreMethods {

    function test_measure_supply_APY_lend_USDC() public {
        //Pre-conditions
        assertTrue(USDC.balanceOf(second_owner) > 0, 'custom: USDC check failed');

        //Action
        _lend(second_owner, address(USDC), USDC.balanceOf(second_owner));

        //Post-conditions
        UserAccountData memory userData = OZ.getUserAccountData(second_owner);
        assertTrue(sUSDe_PT_26SEP.balanceOf(userData.internalAccount) > 0, 'custom: PT check failed');

    }

}