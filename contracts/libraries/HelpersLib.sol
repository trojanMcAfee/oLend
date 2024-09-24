// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";


library HelpersLib {

    function abs(int num) public pure returns (uint) {
        if (num < 0) return uint(-num);
        return uint(num);
    }

    
    function completeZeroAddr(address[] memory arr_) internal pure returns(address[11] memory newArr) {
        uint length = arr_.length;

        for (uint i=0; i < length; i++) {
            if (arr_[i] != address(0)) {
                newArr[i] = arr_[i];
            } else {
                newArr[i] = address(0);
            }
        }
    }

    //not used
    function completeZeroUint(uint[][] memory arr_) internal pure returns(uint[5][5] memory newArr) {
        uint length = arr_.length;

        for (uint i=0; i < length; i++) { 
            for (uint j=0; j < length; j++) {
                if (arr_[i][2] != 0) {
                    newArr[i][j] = arr_[i][j];
                } else {
                    newArr[i] = [uint(0),uint(0),uint(0),uint(0),uint(0)];
                }
            }
        }
    }

    function initArray2D() internal pure returns(uint[][] memory cacheUint) {
        uint outerLength = 5;
        uint innerLength = 5;

        cacheUint = new uint[][](outerLength);

        for (uint i = 0; i < outerLength; i++) {
            cacheUint[i] = new uint[](innerLength);
        }

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