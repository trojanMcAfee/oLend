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
error OZError03(); //func: rebase()
//PT rate hasn't increased
error OZError04(); //func: rebase()

/**
 * WadRayMath.sol and PercentageMath.sol
 */
 //Math multiplication overflow
 error OZError05(); //func: wadMul() - wadDiv() - rayMul() - rayDiv() - wadToRay() / percentMul() - percentDiv()
 //Math addition overflow
 error OZError06(); //func: rayToWad()
 //Math division by zero
 error OZError07(); //func: wayDiv() - rayDiv() / percentDiv()

 /**
  * ozTokenDebt.sol
  */
  //Operation not supported
  error OZError08(); //funcs: all the ones that apply to transfers 