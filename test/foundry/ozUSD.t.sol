// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "./CoreMethods.sol";
import {Tokens} from "../../contracts/AppStorage.sol";


contract ozUSDTest is CoreMethods {

    function test_lend() public {
        _lend(owner, true);
    }

    function test_borrow_and_mint_ozUSD() public {
        _borrow_and_mint_ozUSD();
    }

    //done
    function test_redeem_ozUSD_for_sDAI() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.sDAI);
    }

    //done
    function test_redeem_ozUSD_for_FRAX() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.FRAX);
    }

    //done
    function test_redeem_ozUSD_for_USDC() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.USDC);
    }

    //done
    function test_redeem_ozUSD_for_WETH() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.WETH);
    }

    //working on...
    function test_redeem_ozUSD_for_WBTC() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.WBTC);
    }


    function test_redeem_ozUSD_for_USDe() internal {


    }

}