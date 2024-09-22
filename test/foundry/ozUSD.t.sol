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

    function test_redeem_ozUSD_for_WETH() public {
        _borrow_and_mint_ozUSD();
        _redeem_ozUSD(Tokens.WETH);
    }


}