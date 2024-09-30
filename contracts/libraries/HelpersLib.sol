// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";


library HelpersLib {

    function computeAPY(uint aprScaled) internal pure returns (uint) {
        uint SCALING_FACTOR = 1e18;
        uint x = aprScaled; // x_scaled
        uint sum = SCALING_FACTOR; // Initialize sum with 1 in scaled form
        uint term = x; // First term is x
        uint n = 1; // Start with n=1

        sum += term; // Add the first term

        // Now compute subsequent terms until term is negligibly small
        for (n = 2; n <= 10; n++) {
            // term = (term * x) / (n * SCALING_FACTOR)
            term = (term * x) / (SCALING_FACTOR * n);
            if (term == 0) {
                break; // Break if term is too small to affect the sum
            }
            sum += term;
        }

        uint apyScaled = sum - SCALING_FACTOR;
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