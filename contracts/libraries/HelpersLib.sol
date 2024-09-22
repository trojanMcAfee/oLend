// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;



library HelpersLib {

    function abs(int num) public pure returns (uint) {
        if (num < 0) return uint(-num);
        return uint(num);
    }

}