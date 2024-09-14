// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {CoreMethods} from "../CoreMethods.sol";


contract Lend is CoreMethods {
    modifier whenLendIsCalled() {
        _;
    }

    function test_GivenThatTwoUsersHaveLentFunds() external whenLendIsCalled {
        // it should both delegate credit to OZ diamond
    }

    modifier givenThatTokenInIsETH() {
        _;
    }

    function test_GivenThatAmountInIsSameAsMsgValue() external whenLendIsCalled givenThatTokenInIsETH {
        _borrow_and_mint_ozUSD(true);
    }

    function test_GivenThatAmountInIsNotTheSameAsMsgValue() external whenLendIsCalled givenThatTokenInIsETH {
        // it should throw error
    }

    function test_GivenThatTokenInIsWETH() external whenLendIsCalled {
        // it should mint ozUSD
    }

    function test_GivenThatTokenInIsAStablecoin() external whenLendIsCalled {
        // it should mint ozUSD
    }

    function test_GivenThatAmountInIsZero() external whenLendIsCalled {
        // it should throw error
    }

    function test_GivenTokenInIsNotAuthorizedCollateral() external whenLendIsCalled {
        // it should throw error
    }
}
