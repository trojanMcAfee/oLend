// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";


library HelpersLib {

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