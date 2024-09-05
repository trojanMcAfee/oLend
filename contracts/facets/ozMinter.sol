// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


// import {AppStorage} from "../AppStorage.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
// import {LimitOrderData} from "@pendle/core-v2/contracts/interfaces/IPAllActionTypeV3.sol";
// import {LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {StructGen} from "../StructGen.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

import "forge-std/console.sol";


contract ozMinter is StructGen {

    using SafeERC20 for *;

    function lend(bool isETH_) external payable {
        console.log('aavePoolProvider in lend: ', address(s.aavePoolProvider));
        address aavePool = s.aavePoolProvider.getPool();
        
        if (isETH_) {
            s.aaveGW.depositETH{value: msg.value}(aavePool, address(this), 0);
            return;
        }
    }

    function borrow(uint amount_) external {
        address aavePool = s.aavePoolProvider.getPool();

        IPool(aavePool).borrow(address(s.USDC), amount_, s.VARIABLE_RATE, 0, address(this));

        // s.USDC.safeApprove(address(s.pendleRouter), amount_); //<----- here

        uint minPTout = 0;
        (uint256 netPtOut,,) = s.pendleRouter.swapExactTokenForPt(
            address(this), 
            address(s.sUSDeMarket), 
            minPTout, 
            defaultApprox, 
            createTokenInputStruct(address(s.USDC), s.USDC.balanceOf(address(this))), 
            emptyLimit
        );

        console.log('netPtOut: ', netPtOut);
    }


}