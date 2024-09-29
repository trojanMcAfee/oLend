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

    function _lend(address user_, uint amountIn_, bool isETH_) internal {
        address tokenIn;
        uint msgValue;

        if (isETH_) {
            tokenIn = ETH;
            msgValue = amountIn_;

            assertTrue(amountIn_ == 1 ether, 'assert -_lend: user_ not enough balance');
        } else {
            tokenIn = address(USDC);
            msgValue = 0;
        }

        //User LENDS 
        vm.prank(user_);
        // uint amountIn = 1 ether;
        // console.log('msgValue: ', msgValue);
        // console.log('amountIn_: ', amountIn_);
        // console.log('msg.value: ', msg.value);
        uint initUserBal = user_.balance;

        OZ.lend{value: msgValue}(amountIn_, tokenIn, true);

        assertTrue(user_.balance == initUserBal - 1 ether, 'assert -_lend: userBal  check');

        //---------
        // address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;
        // (uint totalCollateralBase,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(internalAccount);
        // console.log('eth value of eth lent: ', totalCollateralBase);
   
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


    function _borrow_and_mint_ozUSD() internal {
        //User LENDS 
        assertTrue(ozUSD.balanceOf(owner) == 0, '_borrow_and_mint_ozUSD: not 0');

        _lend(owner, owner.balance, true);
        UserAccountData memory userData = OZ.getUserAccountData(owner);

        //User BORROWS
        vm.startPrank(owner);
        OZ.borrow(userData.availableBorrowsBase, owner);
        vm.stopPrank();

        uint balanceOwnerOzUSD = ozUSD.balanceOf(owner);
        assertTrue(balanceOwnerOzUSD > 0, '_borrow_and_mint_ozUSD: bal ozUSD is 0');
    }

    //-------------


    function test_do_accounting() public {
        _borrow_and_mint_ozUSD();

        address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;

        console.log('usdc debt intAcc - aave: ', aaveVariableDebtUSDC.balanceOf(internalAccount));
        console.log('usdc debt oz - aave: ', aaveVariableDebtUSDC.balanceOf(address(0)));
        console.log('PT oz - pendle: ', sUSDe_PT_26SEP.balanceOf(address(OZ)));
        console.log('aweth intAcc: ', aWETH.balanceOf(internalAccount));
        console.log('aweth oz: ', aWETH.balanceOf(address(OZ)));

        

    }


}