// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {ABDKMath64x64} from "./ABDKMath64x64.sol";


library HelpersLib {

    using ABDKMath64x64 for *;

    function computeAPY(uint aprScaled) internal pure returns (uint) {
        // Convert APR from scaled integer (1e18) to 64.64 fixed-point format
        int128 apr64x64 = aprScaled.divu(1e18);

        // Compute e^(apr) - 1 using the ABDKMath64x64 library
        int128 expApr = apr64x64.exp();
        int128 one = (1).fromInt();
        int128 apy64x64 = expApr.sub(one);

        // Convert APY back to scaled integer (1e18)
        uint256 apyScaled = apy64x64.mulu(1e18);

        return apyScaled;
    }


    function abs(int num) public pure returns (uint) {
        if (num < 0) return uint(-num);
        return uint(num);
    }


    function createTokenInputStruct(
        address tokenIn_, 
        uint netTokenIn_,
        SwapData memory swapData_
    ) internal pure returns (TokenInput memory) {
        return TokenInput({
            tokenIn: tokenIn_,
            netTokenIn: netTokenIn_,
            tokenMintSy: tokenIn_,
            pendleSwap: address(0),
            swapData: swapData_
        });
    }


    function createTokenOutputStruct(
        address tokenOut_, 
        uint minTokenOut_,
        SwapData memory swapData_
    ) internal pure returns (TokenOutput memory) {
        return TokenOutput({
            tokenOut: tokenOut_,
            minTokenOut: minTokenOut_,
            tokenRedeemSy: tokenOut_,
            pendleSwap: address(0),
            swapData: swapData_
        });
    }


}