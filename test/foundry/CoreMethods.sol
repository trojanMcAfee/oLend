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

    function _lend(address user_, Tokens token_) internal {
        uint currETHbal = user_.balance;
        if (token_ == Tokens.WETH) assertTrue(currETHbal == 100 * 1 ether, '_lend: user_ not enough balance');

        //User LENDS 
        vm.prank(user_);
        uint amountIn = 1 ether;
        OZ.lend{value: amountIn}(amountIn, true);

        assertTrue(user_.balance == currETHbal - 1 ether);

        //---------
        address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;
        (uint totalCollateralBase,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(internalAccount);
        console.log('eth value of eth lent: ', totalCollateralBase);
   
    }

    

    function _borrow_and_mint_ozUSD(Tokens token_) internal {
        //User LENDS 
        assertTrue(ozUSD.balanceOf(owner) == 0, '_borrow_and_mint_ozUSD: not 0');

        _lend(owner, token_);
        UserAccountData memory userData = OZ.getUserAccountData(owner);

        //User BORROWS
        vm.startPrank(owner);
        OZ.borrow(userData.availableBorrowsBase, owner);
        vm.stopPrank();

        console.log('');
        console.log('--- in _borrow_and_mint ---');

        uint balanceOwnerOzUSD = ozUSD.balanceOf(owner);
        console.log('ozUSD owner bal: ', balanceOwnerOzUSD);

        console.log('getPtToSyRate: ', sUSDeMarket.getPtToSyRate(twapDuration));
        console.log('getPtToAssetRate: ', sUSDeMarket.getPtToAssetRate(twapDuration));
        console.log('');

        //get this ^ assetRate and then come up with ozUSD - PT - asset rate, which will
        //be used for redeeming from ozUSD to the user token

        vm.prank(address(OZ));
        sUSDe_PT_26SEP.approve(address(pendleRouter), type(uint).max);

        vm.startPrank(owner);
        ozUSD.approve(address(OZ), balanceOwnerOzUSD);

        console.log('');
        console.log('ozUSD bal owner - pre redeemption - not 0:', ozUSD.balanceOf(owner));
        console.log('WETH bal owner - pre redeeption - 0: ', WETH.balanceOf(owner));

        ozUSD.redeem(balanceOwnerOzUSD, owner, owner, Tokens.WETH);
        vm.stopPrank();

        console.log('');
        console.log('ozUSD bal owner - post redeemption - 0:', ozUSD.balanceOf(owner));
        console.log('WETH bal owner - post redeeption - not 0: ', WETH.balanceOf(owner));
        console.log('WETH bal oz - post redeemption - 0: ', WETH.balanceOf(owner));

        revert('here3');


        uint ptQuote = OZ.quotePT();

        //External user BUYS discounted PT
        vm.startPrank(second_owner);
        USDC.approve(address(OZ), type(uint).max);
        OZ.rebuyPT(ptQuote / 1e12);

        //External user MINTS ozUSDtoken to user when buying discounted PT
        OZ.finishBorrow(owner);
        vm.stopPrank();

        uint balanceOzUSD = ozUSD.balanceOf(owner);
        console.log('balanceOzUSD - owner: ', balanceOzUSD);
        assertTrue(balanceOzUSD > 0, '_borrow_and_mint_ozUSD: is 0');
        //put this ^ as a ratio of discount to face-value PT instead of balanceOzUSD > 0
    }

    function _redeem_ozUSD() internal {
        uint ozUSDbalance = ozUSD.balanceOf(owner);
        console.log('ozUSDbalance: ', ozUSDbalance);

        vm.startPrank(owner);
        ozUSD.approve(address(OZ), ozUSDbalance);
        // ozUSD.redeem(ozUSDbalance, owner);
    }


    function test_do_accounting() public {
        _borrow_and_mint_ozUSD(Tokens.WETH);

        address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;

        console.log('usdc debt oz - aave: ', aaveVariableDebtUSDC.balanceOf(internalAccount));
        console.log('PT oz - pendle: ', sUSDe_PT_26SEP.balanceOf(address(OZ)));
        console.log('usdc oz: ', USDC.balanceOf(address(OZ)));

    }


}