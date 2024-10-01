// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IERC20} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";

import "forge-std/console.sol";


contract ozRelayer {

    using SafeERC20 for IERC20;

    function borrowInternal(uint amount_, address receiver_, address account_) external {
        IPool aavePool = IPool(0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2);
        IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
        uint variableRate = 2;

        aavePool.borrow(address(USDC), amount_, variableRate, 0, account_);

        USDC.safeTransfer(msg.sender, amount_);
    }

}