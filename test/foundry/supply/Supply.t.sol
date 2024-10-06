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
        uint amountIn = USDC.balanceOf(second_owner);
        
        vm.startPrank(second_owner);
        USDC.approve(address(OZ), amountIn);

        vm.expectEmit(false, false, false, true);
        emit NewAccountDataState(
            amountIn,
            uint16(7500),
            7800,
            type(uint).max
        );

        OZ.lend(amountIn, address(USDC));

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