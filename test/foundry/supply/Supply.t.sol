// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "../CoreMethods.sol";
import {UserAccountData} from "../../../contracts/AppStorage.sol";

import "forge-std/console.sol";

contract SupplyTest is CoreMethods {

    function test_supply_USDC() public {
        _lend(second_owner, address(USDC), USDC.balanceOf(second_owner));

        UserAccountData memory userData = OZ.getUserAccountData(second_owner);

        console.log('internalAccount: ', userData.internalAccount);
        console.log('totalCollateralBase: ', userData.totalCollateralBase);
        console.log('totalDebtBase: ', userData.totalDebtBase);
        console.log('availableBorrowsBase: ', userData.availableBorrowsBase);
        console.log('currentLiquidationThreshold: ', userData.currentLiquidationThreshold);
        console.log('ltv: ', uint(userData.ltv));
        console.log('healthFactor: ', userData.healthFactor);
    }

}