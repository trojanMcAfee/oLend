// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


// import {AppStorage} from "../AppStorage.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
// import {LimitOrderData} from "@pendle/core-v2/contracts/interfaces/IPAllActionTypeV3.sol";
// import {LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {StructGen} from "../StructGen.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPActionSwapPTV3} from "@pendle/core-v2/contracts/interfaces/IPActionSwapPTV3.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import "@pendle/core-v2/contracts/interfaces/IPMarket.sol";

import "forge-std/console.sol";


contract ozMinter is StructGen {

    using SafeERC20 for IERC20;

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

        uint minTokenOut = 0;

        //using uniswap here for simplicity atm. This would need to be fixed for a more efficient method. 
        uint sUSDeOut = _swapUni(
            address(s.USDC), 
            address(s.sUSDe), 
            address(this), 
            s.USDC.balanceOf(address(this)), 
            minTokenOut
        );

        console.log('sUSDeOut in borrow - after swapUni: ', sUSDeOut);
        console.log('sUSDe bal: ', s.sUSDe.balanceOf(address(this)));

        // s.USDC.safeApprove(address(s.pendleRouter), amount_); <---- this is not working idk why - 2nd instance of issue 
        s.sUSDe.approve(address(s.pendleRouter), sUSDeOut);

        uint minPTout = 0;
        // console.log('stamp: ', block.timestamp);

        // bytes memory data = abi.encodeWithSelector(
        //     'swapExactTokenForPt(address,address,uint256,(uint256,uint256,uint256,uint256,uint256),(address,uint256,address,address))', //IPActionSwapPTV3.swapExactTokenForPt.selector
        //     address(this), 
        //     address(s.sUSDeMarket), 
        //     minPTout, 
        //     defaultApprox, 
        //     createTokenInputStruct(address(s.sUSDe), sUSDeOut), 
        //     emptyLimit
        // );

        // (bool s,) = address(s.pendleRouter).delegatecall(data);
        // require(s, "fff");


        (uint256 netPtOut,,) = s.pendleRouter.swapExactTokenForPt(
            address(this), 
            address(s.sUSDeMarket), 
            minPTout, 
            s.defaultApprox, 
            createTokenInputStruct(address(s.sUSDe), sUSDeOut), 
            s.emptyLimit
        );

        // console.log('netPtOut - sUSDe: ');
        console.log('netPtOut - sUSDe: ', netPtOut);
    }

    function do_swap() public {
        // // LimitOrderData memory emptyLimit2;
        // (uint256 netPtOut,,) = s.pendleRouter.swapExactTokenForPt(
        //     address(this), 
        //     address(s.sUSDeMarket), 
        //     0, 
        //     ApproxParams(0, type(uint256).max, 0, 256, 1e14), 
        //     createTokenInputStruct(address(s.sUSDe), 1000 * 1e18), 
        //     emptyLimit
        // );

        // console.log('netPtOut - sUSDe: ', netPtOut);
    }


    //************* */

    function _swapUni(
        address tokenIn_,
        address tokenOut_,
        address receiver_,
        uint amountIn_, 
        uint minAmountOut_
    ) private returns(uint) {
        ISwapRouter swapRouterUni = ISwapRouter(0xE592427A0AEce92De3Edee1F18E0157C05861564);
        // IERC20(tokenIn_).safeApprove(address(swapRouterUni), amountIn_); //<--- not working dont know why
        IERC20(tokenIn_).approve(address(swapRouterUni), amountIn_);
        uint24 poolFeed = 500;

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenIn_, poolFeed, address(s.USDT), poolFeed, tokenOut_), //500 -> 0.05
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minAmountOut_
            });

        return swapRouterUni.exactInput(params);
    }

}