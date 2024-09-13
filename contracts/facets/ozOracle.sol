// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {AppStorage} from "../AppStorage.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";

import "forge-std/console.sol";

contract ozOracle {

    AppStorage private s;

    using PendlePYOracleLib for IPMarket;
    using FixedPointMathLib for uint;

    function quotePT() external view returns(uint) {
        uint balancePT = s.pendlePT.balanceOf(address(this));
        uint discount = s.ptDiscount.mulDivDown(balancePT, 10_000);
        uint discountedPT = balancePT - discount;

        uint ptToAssetRate = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        uint quoteInStable = discountedPT.mulDivDown(ptToAssetRate, 1 ether);

        return quoteInStable;
    }

}