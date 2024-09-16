// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {Setup} from "./Setup.sol";
import {IERC20} from "../../contracts/interfaces/IERC20.sol";
import {UserAccountData} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";


contract CoreMethods is Setup {

    function _lend(address user_, bool isETH_) internal {
        uint currETHbal = user_.balance;
        if (isETH_) assertTrue(currETHbal == 100 * 1 ether, '_lend: user_ not enough balance');

        //User LENDS 
        vm.prank(user_);
        uint amountIn = 1 ether;
        OZ.lend{value: amountIn}(amountIn, true);

        assertTrue(user_.balance == currETHbal - 1 ether);
    }

    function _delegateCredit() internal {
        _lend(owner, true);

        address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;
        (,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(internalAccount);
        // (,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(address(OZ));
        uint amountBorrow = 1000 * 1e6;
        // uint amountBorrow = (availableBorrowsBase / 1e2) - (1 * 1e6);

        // console.log('availableBorrowsBase: ', availableBorrowsBase);
        console.log('');

        vm.prank(owner);
        OZ.borrow(amountBorrow, address(0));
    }

    function _borrow_and_mint_ozUSD(bool isETH_) internal {
        //User LENDS 
        assertTrue(ozUsd.balanceOf(owner) == 0, '_borrow_and_mint_ozUSD: not 0');

        _lend(owner, true);

        //-----
        console.log('');
        console.log('--- in _borrow_and_mint_ozUSD ---');

        UserAccountData memory userData = OZ.getUserAccountData(owner);
        console.log('availableBorrowsBase user: ', userData.availableBorrowsBase);
        //-----

        address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;
        (,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(internalAccount);
        console.log('availableBorrowsBase int acc in test - aave: ', availableBorrowsBase);

        // uint toBorrow = (availableBorrowsBase / 1e2) - (1 * 1e6);
        uint toBorrow = userData.availableBorrowsBase;
        console.log('toBorrow - _borrow test - same as revertDiscount(): ', toBorrow);
        console.log('');

        //User BORROWS
        vm.startPrank(owner);
        OZ.borrow(toBorrow, owner);
        vm.stopPrank();

        uint ptQuote = OZ.quotePT();

        //External user BUYS discounted PT
        vm.startPrank(second_owner);
        IERC20(USDCaddr).approve(address(OZ), type(uint).max);
        OZ.rebuyPT(ptQuote / 1e12);

        //External user MINTS ozUSD to user when buying discounted PT
        OZ.finishBorrow(owner);
        vm.stopPrank();

        uint balanceOzUSD = ozUsd.balanceOf(owner);
        console.log('balanceOzUSD - owner: ', balanceOzUSD);
        assertTrue(balanceOzUSD > 0, '_borrow_and_mint_ozUSD: is 0');
        //put this ^ as a ratio of discount to face-value PT instead of balanceOzUSD > 0
    }


}