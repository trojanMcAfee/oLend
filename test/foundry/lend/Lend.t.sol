// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {CoreMethods} from "../CoreMethods.sol";
import {Tokens} from "../../../contracts/AppStorage.sol";


contract Lend is CoreMethods {
    modifier whenLendIsCalled() {
        _;
    }

    //NEW
    function test_GivenThatOneUserHasLentFunds() external whenLendIsCalled {
        //it should lend funds and delegate credit to ozRelayer
        // _lend(owner, true); //<--- catch the delegation on this test using the FundsDelegated event on depositInAave()
    }

    function test_GivenThatTwoUsersHaveLentFunds() external whenLendIsCalled {
        // it should both delegate credit to OZ diamond
    }

    modifier givenThatTokenInIsETH() {
        _;
    }

    function test_GivenThatAmountInIsSameAsMsgValue() external whenLendIsCalled givenThatTokenInIsETH {
        //it should mint ozUSDtoken by borrowing
        _borrow_and_mint_ozUSD();
    }

    //NEW
    function test_2_GivenThatAmountInIsSameAsMsgValue() external whenLendIsCalled givenThatTokenInIsETH {
        //it should redeem ozUSDtoken for full amount
        _borrow_and_mint_ozUSD();

    }

    function test_GivenThatAmountInIsNotTheSameAsMsgValue() external whenLendIsCalled givenThatTokenInIsETH {
        // it should throw error
    }

    function test_GivenThatTokenInIsWETH() external whenLendIsCalled {
        // it should mint ozUSDtoken
    }

    function test_GivenThatTokenInIsAStablecoin() external whenLendIsCalled {
        // it should mint ozUSDtoken
    }

    function test_GivenThatAmountInIsZero() external whenLendIsCalled {
        // it should throw error
    }

    function test_GivenTokenInIsNotAuthorizedCollateral() external whenLendIsCalled {
        // it should throw error
    }
}
