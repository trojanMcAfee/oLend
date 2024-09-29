// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";
// import {IERC20} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IERC20} from "./interfaces/IERC20.sol";
// import {ozRelayer} from "./ozRelayer.sol";

import "forge-std/console.sol";


contract InternalAccount {

    address public relayer;
    address ETH;
    IWrappedTokenGatewayV3 aaveGW;
    IPool aavePool;
    ICreditDelegationToken aaveVariableDebtUSDCDelegate;

    event FundsDelegated(address indexed internalAccount, uint indexed amount);

    constructor(
        address relayer_, 
        address eth_, 
        address aaveGW_, 
        address aavePool_, 
        address aaveDebtUsdc_
    ) {
        relayer = relayer_;
        ETH = eth_;
        aaveGW = IWrappedTokenGatewayV3(aaveGW_);
        aavePool = IPool(aavePool_);
        aaveVariableDebtUSDCDelegate = ICreditDelegationToken(aaveDebtUsdc_);
    }

    function internalApprove(address tokenIn_, uint amountIn_) external {
        IERC20(tokenIn_).approve(address(aavePool), amountIn_);
    }

    function depositInAave(uint amountIn_, address tokenIn_) public payable { //<--- change depositInAave to depositAndDelegate
        if (tokenIn_ == ETH) {
            aaveGW.depositETH{value: msg.value}(address(aavePool), address(this), 0); //0 --> refCode
        } else {
            IERC20(tokenIn_).approve(address(aavePool), amountIn_);
            aavePool.supply(tokenIn_, amountIn_, address(this), 0);
        }

        // ICreditDelegationToken aaveVariableDebtUSDCDelegate = ICreditDelegationToken(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
        aaveVariableDebtUSDCDelegate.approveDelegation(relayer, type(uint).max);
        
        emit FundsDelegated(address(this), msg.value);
    }

}