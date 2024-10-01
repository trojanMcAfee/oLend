// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "./CoreMethods.sol";
import {Tokens} from "../../contracts/AppStorage.sol";

import "forge-std/console.sol";

contract ozUSDTest is CoreMethods {

    function test_lend_ETH() public {
        _lend(owner, ETH, 1 ether);
    }

    function test_lend_USDC() public {
        _lend(second_owner, address(USDC), USDC.balanceOf(second_owner));
    }

    function test_borrow_and_mint_ozUSD() public {
        _borrow_and_mint_ozUSD(ETH);
    }

    function test_redeem_ozUSD_for_sDAI() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.sDAI);
    }

    function test_redeem_ozUSD_for_FRAX() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.FRAX);
    }

    function test_redeem_ozUSD_for_USDC() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.USDC);
    }

    function test_redeem_ozUSD_for_WETH() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.WETH);
    }

    function test_redeem_ozUSD_for_WBTC() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.WBTC);
    }

    function test_redeem_ozUSD_for_sUSDe() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.sUSDe);
    }

    
    function test_redeem_ozUSD_for_USDe() public {
        _borrow_and_mint_ozUSD(ETH);
        _redeem_ozUSD(Tokens.USDe);
    }


    //------------
    function test_do_my_accounting() public {
        address testToken = address(WETH);
        address intOwner = _borrow_and_mint_ozUSD(testToken);

        address internalAccount = OZ.getUserAccountData(intOwner).internalAccount;
        console.log('intAcc: ', internalAccount);

        console.log('usdc debt intAcc - aave: ', aaveVariableDebtUSDC.balanceOf(internalAccount));
        console.log('PT oz - pendle: ', sUSDe_PT_26SEP.balanceOf(address(OZ)));
        console.log('aweth intAcc: ', aWETH.balanceOf(internalAccount));
        console.log('');

        uint borrowingRate = OZ.getBorrowingRates(testToken);
        console.log('borrowingRate aave lentToken - apy: ', borrowingRate);

        (uint aaveSupplyAPY, uint pendleFixedAPY) = OZ.getSupplyRates(testToken);
        console.log('supplyRate aave weth - apy: ', aaveSupplyAPY);
        console.log('pendle fixed apy: ', pendleFixedAPY);
        console.log('');

        uint netAPY = OZ.getNetAPY(testToken);
        console.log('netAPY: ', netAPY);
    }

}