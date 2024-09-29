// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "./CoreMethods.sol";
import {Tokens} from "../../contracts/AppStorage.sol";


contract ozUSDTest is CoreMethods {

    function test_lend_ETH() public {
        _lend(owner, 1 ether, true);
    }

    function test_lend_USDC() public {
        _lend(owner, USDC.balanceOf(second_owner), false);
    }

    function test_borrow_and_mint_ozUSD() public {
        _borrow_and_mint_ozUSD();
    }

    function test_redeem_ozUSD_for_sDAI() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.sDAI);
    }

    function test_redeem_ozUSD_for_FRAX() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.FRAX);
    }

    function test_redeem_ozUSD_for_USDC() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.USDC);
    }

    function test_redeem_ozUSD_for_WETH() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.WETH);
    }

    function test_redeem_ozUSD_for_WBTC() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.WBTC);
    }

    function test_redeem_ozUSD_for_sUSDe() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.sUSDe);
    }

    
    function test_redeem_ozUSD_for_USDe() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.USDe);
    }

}