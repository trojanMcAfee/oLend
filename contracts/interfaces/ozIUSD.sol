// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IERC20} from "./IERC20.sol";
import {Tokens} from "../AppStorage.sol";


interface ozIUSD is IERC20 {
    function redeem(
        uint amount, 
        uint minAmountOut,
        address account, 
        address receiver, 
        Tokens token
    ) external returns(uint);
}