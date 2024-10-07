// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IERC20} from "./IERC20.sol";


interface ozIERC20 is IERC20 {
    function rebase() external;
}