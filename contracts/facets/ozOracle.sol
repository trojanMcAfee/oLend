// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {AppStorage} from "../AppStorage.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {State} from "../State.sol";
import {ABDKMath64x64} from "../libraries/ABDKMath64x64.sol";

import "forge-std/console.sol";

contract ozOracle is State {

    using PendlePYOracleLib for IPMarket;
    using FixedPointMathLib for uint;

    /**
     * Returns the quote in stable (USDC, USDe) of the PT with the 
     * discount already applied to it
     */
    function quotePT() external view returns(uint quoteInStable) { 
        uint balancePT = s.pendlePT.balanceOf(address(this));
        uint ptToAssetRate = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        uint balancePTinAsset = balancePT.mulDivDown(ptToAssetRate, 1 ether);
        uint discount = s.ptDiscount.mulDivDown(balancePTinAsset, 10_000);
        quoteInStable = balancePTinAsset - discount;
    }

    function getVariableBorrowAPY() external view returns(uint) {
        //get PT's APY
        uint ptPrice = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        uint ytPrice = s.sUSDeMarket.getYtToAssetRate(s.twapDuration);
        // uint secsInDay = 86400;
        uint daysToExp = (s.sUSDeMarket.expiry() - block.timestamp) / 86400;
        // uint scalingFactor = 1e18;

        console.log('');
        console.log('ptPrice: ', ptPrice);
        console.log('ytPrice: ', ytPrice);
        console.log('s.sUSDeMarket.expiry(): ', s.sUSDeMarket.expiry());
        console.log('block.timestamp: ', block.timestamp);
        console.log('daysToExp ***: ', daysToExp);
        console.log('');

        uint ytScaled = ytPrice * 1e18;
        uint ratio = ytScaled / ptPrice;
        uint base = 1e18 + ratio;
        uint exponent = (365 * 1e18) / daysToExp;

        //----------
        // uint result = base ** (exponent / scalingFactor);
        // uint x = result - scalingFactor;

        // uint apy = ( (1 + ytPrice / ptPrice) ** (365 / daysToExp) ) - 1;
        //----------

        // Convert scaled values to ABDKMath64x64 format
        int128 abdkBase = ABDKMath64x64.divu(base, 1e18); // base / 1e18
        int128 abdkExponent = ABDKMath64x64.divu(exponent, 1e18); // exponent / 1e18

        // Step 7: Compute natural logarithm of the base
        int128 lnBase = ABDKMath64x64.ln(abdkBase);

        // Step 8: Multiply exponent with ln(base)
        int128 exponentLnBase = ABDKMath64x64.mul(abdkExponent, lnBase);

        // Step 9: Compute the exponential
        int128 abdkResult = ABDKMath64x64.exp(exponentLnBase);

        // Step 10: Convert the result back to uint256 and scale it
        uint256 apyPlusOne = ABDKMath64x64.mulu(abdkResult, 1e18);

        // Step 11: Subtract scalingFactor to get the APY
        uint256 apy = apyPlusOne - 1e18;
        
        return apy;        
    }

    function getVariableSupplyAPY() external view returns(uint) {

    }

}