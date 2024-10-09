// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {AppStorage} from "../AppStorage.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {State} from "../State.sol";
import {ABDKMath64x64} from "../libraries/ABDKMath64x64.sol";
import {HelpersLib} from "../libraries/HelpersLib.sol";

import "forge-std/console.sol";


contract ozOracle is State {

    using PendlePYOracleLib for IPMarket;
    using FixedPointMathLib for uint;
    using ABDKMath64x64 for *;
    using HelpersLib for uint;

    /**
     * Returns the quote in stable (USDC, USDe) of the PT with the 
     * discount already applied to it
     */
     //NOT USED
    function quotePT() external view returns(uint quoteInStable) { 
        uint balancePT = s.pendlePT.balanceOf(address(this));
        uint ptToAssetRate = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        uint balancePTinAsset = balancePT.mulDivDown(ptToAssetRate, 1 ether);
        uint discount = s.ptDiscount.mulDivDown(balancePTinAsset, 10_000);
        quoteInStable = balancePTinAsset - discount;
    }

    function getVariableBorrowAPY() external view returns(uint apy) {}

    function getInternalSupplyRate() external view returns(uint) {
        uint ptPrice = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        return ptPrice;
    }

    function _calculatePendleFixedAPY(bool formatted_) private view returns(uint) {
        uint ptPrice = s.sUSDeMarket.getPtToAssetRate(s.twapDuration);
        uint ytPrice = s.sUSDeMarket.getYtToAssetRate(s.twapDuration);
        uint daysToExp = (s.sUSDeMarket.expiry() - block.timestamp) / 86400;
        uint DECIMALS = formatted_ ? 1e10 : 1;

        uint ytScaled = ytPrice * s.SCALE;
        uint ratio = ytScaled / ptPrice;
        uint base = s.SCALE + ratio;
        uint exponent = (365 * s.SCALE) / daysToExp;

        // Convert scaled values to ABDKMath64x64 format
        int128 abdkBase = base.divu(s.SCALE); 
        int128 abdkExponent = exponent.divu(s.SCALE); 

        /**
        - Compute natural logarithm of the base.
        - Multiply exponent with ln(base).
        - Compute the exponential.
        - Convert the result back to uint256 and scale it.
        - Subtract SCALE to get the APY.
         */
        return (abdkExponent
            .mul(abdkBase.ln())
            .exp()
            .mulu(s.SCALE)
            - s.SCALE)
            / DECIMALS;
    }

    
    function getNetAPY(address token_) external view returns(uint) {
        uint aaveBorrowAPY = getBorrowingRates(token_, false);
        (uint aaveSupplyAPY, uint pendleFixedAPY) = getSupplyRates(token_, false);
        uint netAPY = pendleFixedAPY + aaveSupplyAPY - aaveBorrowAPY;

        return netAPY;
    }


    /**
     formatted_ is for formatting the returned rate into a 100% scale and with 6 decimals, in order to
     match a 6-decimals token (USDC), when calculating amount of generated debt.
     *
     If false, rate is returned at a 1e18 scale and not formatted to 100%. Meaning that you'd have to multiply
     the final output by 100 (after dividing by 1e18) in order to get a % APY. 
     */
    function getBorrowingRates(address token_, bool formatted_) public view returns(uint) { 
        uint128 currentVariableBorrowRate = s.aavePool.getReserveData(token_).currentVariableBorrowRate;
        uint DECIMALS = token_ == address(s.USDC) && formatted_ ? 1e10 : 1;
        return (uint(currentVariableBorrowRate / 1e9).computeAPY()) / DECIMALS;
    }


    function getSupplyRates(address token_, bool formatted_) public view returns(uint, uint) {
        uint aaveSupplyAPY = _calculateAaveLendAPY(token_, formatted_);
        uint pendleFixedAPY = _calculatePendleFixedAPY(formatted_); 
        return (aaveSupplyAPY, pendleFixedAPY);
    }

    function _calculateAaveLendAPY(address token_, bool formatted_) private view returns(uint) {
        uint DECIMALS = token_ == address(s.USDC) && formatted_ ? 1e10 : 1;
        
        return (uint(
            s.aavePool
            .getReserveData(token_)
            .currentLiquidityRate)
            / 1e9)
            .computeAPY()
            / DECIMALS;
    }


    //Get the rate between ozUSDC and PT (sUSDe-PT)
    // function getExchangeRate() external view returns(uint) {
    //     return s.ozUSDCtoPTrate;
    // }

}