// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";


library HelpersLib {

    function abs(int num) public pure returns (uint) {
        if (num < 0) return uint(-num);
        return uint(num);
    }


    function createTokenInputStruct(address tokenIn, uint256 netTokenIn) internal view returns (TokenInput memory) {
        return TokenInput({
            tokenIn: tokenIn,
            netTokenIn: netTokenIn,
            tokenMintSy: tokenIn
        });
    }


    function createTokenOutputStruct(address tokenOut, uint minTokenOut) internal view returns (TokenOutput memory) {
        return TokenOutput({
            tokenOut: tokenOut,
            minTokenOut: minTokenOut,
            tokenRedeemSy: tokenOut
        });
    }

}