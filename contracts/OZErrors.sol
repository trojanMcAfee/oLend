// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


/**
 * ozMinter.sol
 */
//Unauthorized tokenIn
error OZError01(address tokenIn); //contr: ozMinter - func: lend()
//amountIn is not the same as msg.value
error OZError02(uint amountIn, uint msgValue); //contr: ozMinter - func: lend()

/**
 * ozUSDCtoken.sol
 */
//Too soon to rebase
error OZError03(); //contr: ozUSDCtoken - func: rebase()
//PT rate hasn't increased
error OZError04(); //contr: ozUSDCtoken - func: rebase()