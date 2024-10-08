// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {Setup} from "./Setup.sol";
import {IERC20} from "../../contracts/interfaces/IERC20.sol";
import {UserAccountData} from "../../contracts/AppStorage.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";
import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
// import {AppStorageTest} from "./AppStorageTest.sol";
import {Tokens} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";



contract CoreMethods is Setup {

    using PendlePYOracleLib for IPMarket;

    function _lend(address user_, address tokenIn_, uint amountIn_) internal {
        uint msgValue;

        if (tokenIn_ == ETH) {
            msgValue = amountIn_;
            assertTrue(amountIn_ == 1 ether, 'custom -_lend: user_ not enough balance');
        } else {
            msgValue = 0;

            vm.prank(user_);
            IERC20(tokenIn_).approve(address(OZ), amountIn_);
        }

        //User LENDS 
        uint initUserBal = user_.balance;
        vm.prank(user_);

        OZ.lend{value: msgValue}(amountIn_, tokenIn_, msg.sender);

        UserAccountData memory userData = OZ.getUserAccountData(user_);

        if (tokenIn_ == ETH) {
            assertTrue(user_.balance == initUserBal - 1 ether, 'custom -_lend: userBal  check');
        } else if (tokenIn_ == address(USDC)) {
            // assertTrue(aUSDC.balanceOf(userData.internalAccount) == amountIn_, "custom - _lend: aUSDC check");
        } else if (tokenIn_ == address(WETH)) {
            assertTrue(aWETH.balanceOf(userData.internalAccount) == amountIn_, "custom - _lend: aWETH check");
        }
    }


    function _redeem_ozUSD(Tokens token_) internal {
        //PRE-CONDITIONS
        IERC20 tokenOut = IERC20(_getTokenOut(token_));

        uint balanceOwnerOzUSD = ozUSD.balanceOf(owner);
        assertTrue(balanceOwnerOzUSD > 0);

        vm.prank(address(OZ)); //<--- ozDiamond can't call approve here
        sUSDe_PT_26SEP.approve(address(pendleRouter), type(uint).max);

        vm.startPrank(owner);
        ozUSD.approve(address(OZ), balanceOwnerOzUSD);

        //ACTION
        uint minAmountOut = 0; //<--- has to be with slippage calculation
        uint amountTokenOut = ozUSD.redeem(balanceOwnerOzUSD, minAmountOut, owner, owner, token_);
        vm.stopPrank();

        //POST-CONDITIONS
        uint balanceOwnerTokenOut = tokenOut.balanceOf(owner);

        assertTrue(amountTokenOut > 0);
        assertTrue(ozUSD.balanceOf(owner) == 0);
        assertTrue(balanceOwnerTokenOut == amountTokenOut);
        assertTrue(tokenOut.balanceOf(address(OZ)) == 0);
    }


    function _borrow_and_mint_ozUSD(address lentToken_) internal returns(address intOwner) {
        //User LENDS 
        assertTrue(ozUSD.balanceOf(owner) == 0, 'custom - _borrow_and_mint_ozUSD: not 0');
        intOwner;
        uint amountIn;
        
        if (lentToken_ == ETH) {
            intOwner = owner;
            amountIn = 1 ether;
        } else if (lentToken_ == address(USDC)) {
            intOwner = second_owner;
            amountIn = 1000 * 1e6;
        } else if (lentToken_ == address(WETH)) {
            intOwner = thirdOwner;
            amountIn = 1 ether;
        }

        _lend(intOwner, lentToken_, amountIn);
        UserAccountData memory userData = OZ.getUserAccountData(intOwner);

        //User BORROWS
        vm.startPrank(intOwner);
        console.log('userData.availableBorrowsBase - amount being borrowed ****: ', userData.availableBorrowsBase);
        OZ.borrow(userData.availableBorrowsBase, intOwner);
        vm.stopPrank();

        uint balanceOwnerOzUSD = ozUSD.balanceOf(intOwner);
        assertTrue(balanceOwnerOzUSD > 0, '_borrow_and_mint_ozUSD: bal ozUSD is 0');
    }




}