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
    using ABDKMath64x64 for *;

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
        uint ptPrice = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        uint ytPrice = s.sUSDeMarket.getYtToAssetRate(s.twapDuration);
        uint daysToExp = (s.sUSDeMarket.expiry() - block.timestamp) / 86400;

        uint ytScaled = ytPrice * s.SCALE;
        uint ratio = ytScaled / ptPrice;
        uint base = s.SCALE + ratio;
        uint exponent = (365 * s.SCALE) / daysToExp;

        // Convert scaled values to ABDKMath64x64 format
        int128 abdkBase = base.divu(s.SCALE); 
        int128 abdkExponent = exponent.divu(s.SCALE); 

        // Step 7: Compute natural logarithm of the base
        // int128 lnBase = abdkBase.ln();

        // Step 8: Multiply exponent with ln(base)
        uint apy = abdkExponent
            .mul(abdkBase.ln())
            .exp()
            .mulu(s.SCALE)
            - s.SCALE;

        // Step 9: Compute the exponential
        // int128 abdkResult = exponentLnBase.exp();

        // Step 10: Convert the result back to uint256 and scale it
        // uint256 apyPlusOne = abdkResult.mulu(s.SCALE);

        // Step 11: Subtract scalingFactor to get the APY
        // uint256 apy = apyPlusOne - s.SCALE;
        
        return apy;        
    }

    function getVariableSupplyAPY() external view returns(uint) {

    }

}