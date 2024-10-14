// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IERC20} from "./interfaces/IERC20.sol";
// import {ozRelayer} from "./ozRelayer.sol";
import {IPAllActionV3, SwapData, LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";
import {HelpersLib} from "./libraries/HelpersLib.sol";
import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";

import "forge-std/console.sol";


contract InternalAccount {

    using HelpersLib for address;
    using PendlePYOracleLib for IPMarket;

    address public relayer;
    address ETH;
    IWrappedTokenGatewayV3 aaveGW;
    IPool aavePool;
    ICreditDelegationToken aaveVariableDebtUSDCDelegate;
    //-----------------
    IERC20 public constant USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 public constant sUSDe = IERC20(0x9D39A5DE30e57443BfF2A8307A4256c8797A3497);
    IERC20 public constant USDT = IERC20(0xdAC17F958D2ee523a2206206994597C13D831ec7);
    IPMarket public constant sUSDeMarket = IPMarket(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);
    IPAllActionV3 public constant pendleRouter = IPAllActionV3(0x888888888889758F76e7103c6CbF23ABbF58F946);
    IERC20 public constant sUSDe_PT_26SEP = IERC20(0x6c9f097e044506712B58EAC670c9a5fd4BCceF13);

    ApproxParams defaultApprox = ApproxParams(0, type(uint256).max, 0, 256, 1e14);
    SwapData emptySwap;
    LimitOrderData emptyLimit;

    event FundsDelegated(
        address indexed internalAccount, 
        address indexed depositToken, 
        uint indexed amount
    );

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


    function depositInAave(uint amountIn_, address tokenIn_) public payable { //<--- change depositInAave to depositAndDelegate
        if (tokenIn_ == ETH) {
            aaveGW.depositETH{value: msg.value}(address(aavePool), address(this), 0); //0 --> refCode
        } else {
            IERC20(tokenIn_).approve(address(aavePool), amountIn_);
            aavePool.supply(tokenIn_, amountIn_, address(this), 0);
        }

        aaveVariableDebtUSDCDelegate.approveDelegation(relayer, type(uint).max);
        
        emit FundsDelegated(address(this), tokenIn_, amountIn_);
    }


    function buyPT(uint amountIn_, address intAcc_, address tokenIn_) external returns(uint) {        
        uint sUSDeOut;
        uint minTokenOut = 0;
        
        if (tokenIn_ == address(USDC)) {
            sUSDeOut = _swapUni(
                address(USDC), 
                address(sUSDe), 
                intAcc_, 
                amountIn_, 
                minTokenOut
            );
        }

        console.log('sUSDeOut - swapUni: ', sUSDeOut);

        sUSDe.approve(address(pendleRouter), sUSDeOut);
        uint minPTout = 0;

        (uint amountOutPT,,) = pendleRouter.swapExactTokenForPt(
            intAcc_, 
            address(sUSDeMarket), 
            minPTout, 
            defaultApprox, //check StructGen.sol for a more gas-efficient impl of this
            address(sUSDe).createTokenInputStruct(sUSDeOut, emptySwap), 
            emptyLimit
        );

        console.log('amountOutPT: ', amountOutPT);

        return amountOutPT;
    }

    
    function sellPT(uint amountInPT_, address tokenOut_, address receiver_) external returns(uint) {
        sUSDe_PT_26SEP.approve(address(pendleRouter), amountInPT_);
        uint minTokenOut = 0;

        console.log('amountInPT_: ', amountInPT_);

        (uint sUSDeOut,,) = pendleRouter.swapExactPtForToken(
            address(this), 
            address(sUSDeMarket), 
            amountInPT_, 
            address(sUSDe).createTokenOutputStruct(minTokenOut, emptySwap), 
            emptyLimit
        );

        console.log('amountOut - sUSDe: ', sUSDeOut);

        uint amountOutUSDC;

        if (tokenOut_ == address(USDC)) {
            amountOutUSDC = _swapUni(
                address(sUSDe), 
                address(USDC), 
                receiver_, 
                sUSDeOut, 
                minTokenOut
            );
        }

        console.log('amountOutUSDC - final: ', amountOutUSDC);
    }


    //---------------------------
    function _swapUni(
        address tokenIn_,
        address tokenOut_,
        address receiver_,
        uint amountIn_, 
        uint minAmountOut_
    ) internal returns(uint) {
        ISwapRouter swapRouterUni = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        // IERC20(tokenIn_).safeApprove(address(swapRouterUni), amountIn_); //<--- not working dont know why
        IERC20(tokenIn_).approve(address(swapRouterUni), amountIn_);
        uint24 poolFee = 500;

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenIn_, poolFee, address(USDT), poolFee, tokenOut_), //500 -> 0.05
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minAmountOut_
            });    

        return swapRouterUni.exactInput(params);
    }

}