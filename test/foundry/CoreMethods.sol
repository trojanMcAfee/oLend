// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {Setup} from "./Setup.sol";
import {IERC20} from "../../contracts/interfaces/IERC20.sol";
import {UserAccountData} from "../../contracts/AppStorage.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";

import "forge-std/console.sol";

interface MyICreditDelegationToken {
    function scaledBalanceOf(address) external view returns(uint);
    function balanceOf(address) external view returns(uint);
}


contract CoreMethods is Setup {

    function _lend(address user_, bool isETH_) internal {
        uint currETHbal = user_.balance;
        if (isETH_) assertTrue(currETHbal == 100 * 1 ether, '_lend: user_ not enough balance');

        //User LENDS 
        vm.prank(user_);
        uint amountIn = 1 ether;
        OZ.lend{value: amountIn}(amountIn, true);

        assertTrue(user_.balance == currETHbal - 1 ether);

        //---------
        // address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;
        // (uint totalCollateralBase,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(internalAccount);
        // console.log('availableBorrowsBase: ', availableBorrowsBase);
        // console.log('totalCollateralBase: ', totalCollateralBase);
        // console.log('');

        // UserAccountData memory userData = OZ.getUserAccountData(owner);
        // console.log('userData.availableBorrowsBase: ', userData.availableBorrowsBase);
        // console.log('blockNum: ', block.number);

        // //Then do discount on the APR/Y presented to clients, follwing ptDiscount and where it's applied.
        // //Check the relation with curr ETH price
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
        assertTrue(ozUSD.balanceOf(owner) == 0, '_borrow_and_mint_ozUSD: not 0');

        _lend(owner, true);
        UserAccountData memory userData = OZ.getUserAccountData(owner);

        //User BORROWS
        vm.startPrank(owner);
        OZ.borrow(userData.availableBorrowsBase, owner);
        // vm.stopPrank();

        uint balanceOwnerOzUSD = ozUSD.balanceOf(owner);
        console.log('ozUSD owner bal: ', balanceOwnerOzUSD);

        console.log('getPtToSyRate: ', sUSDeMarket.getPtToSyRate(twapDuration));
        console.log('getPtToAssetRate: ', sUSDeMarket.getPtToAssetRate(twapDuration));

        //get this ^ assetRate and then come up with ozUSD - PT - asset rate, which will
        //be used for redeeming from ozUSD to the user token


        revert('here3');


        // ozUSD.approve(address(OZ), balanceOwnerOzUSD);
        OZ.redeem(balanceOwnerOzUSD, owner, owner);
        vm.stopPrank();


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
        _borrow_and_mint_ozUSD(true);

        address internalAccount = 0xa38D17ef017A314cCD72b8F199C0e108EF7Ca04c;

        console.log('usdc debt oz - aave: ', aaveVariableDebtUSDC.balanceOf(internalAccount));
        console.log('PT oz - pendle: ', sUSDe_PT_26SEP.balanceOf(address(OZ)));
        console.log('usdc oz: ', USDC.balanceOf(address(OZ)));

    }


}