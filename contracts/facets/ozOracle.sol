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
        uint daysToExp = (s.sUSDeMarket.expiry() - block.timestamp) / 86400;
        uint apy = ( (1 + ytPrice / ptPrice) ** (365 / daysToExp) ) - 1;
        
        console.log('ptPrice: ', ptPrice);
        console.log('ytPrice: ', ytPrice);
        console.log('daysToExp: ', daysToExp);
        console.log('apy in getVariableBorrowAPY: ', apy);

        return apy;        

        //get Aave's APY
        //substract both and the discount to get the net APY 
    }

    function getVariableSupplyAPY() external view returns(uint) {

    }

}