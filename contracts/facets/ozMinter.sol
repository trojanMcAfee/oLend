// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


// import {AppStorage} from "../AppStorage.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
// import {LimitOrderData} from "@pendle/core-v2/contracts/interfaces/IPAllActionTypeV3.sol";
// import {LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {StructGen} from "../StructGen.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
// import {IERC20} from "../interfaces/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IPActionSwapPTV3} from "@pendle/core-v2/contracts/interfaces/IPActionSwapPTV3.sol";
import {TokenOutput, LimitOrderData} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IERC20, IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";

import "forge-std/console.sol";

interface MyPendleRouter {
    function swapExactPtForToken(
        address receiver,
        address market,
        uint256 exactPtIn,
        TokenOutput calldata output,
        LimitOrderData calldata limit
    ) external returns (uint256 netTokenOut, uint256 netSyFee, uint256 netSyInterm);
}


contract ozMinter is StructGen {

    using SafeERC20 for IERC20;
    using Address for address;

    function lend(bool isETH_) external payable {
        address aavePool = s.aavePoolProvider.getPool();
        
        if (isETH_) {
            s.aaveGW.depositETH{value: msg.value}(aavePool, address(this), 0);
            return;
        }
    }

    function borrow(uint amount_, address receiver_) external {
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
        console.log('sUSDeOut: ', sUSDeOut);


        // s.USDC.safeApprove(address(s.pendleRouter), amount_); <---- this is not working idk why - 2nd instance of issue 
        s.sUSDe.approve(address(s.pendleRouter), sUSDeOut);

        uint minPTout = 0;
      
        (uint256 netPtOut,,) = s.pendleRouter.swapExactTokenForPt(
            address(this), 
            address(s.sUSDeMarket), 
            minPTout, 
            s.defaultApprox, 
            createTokenInputStruct(address(s.sUSDe), sUSDeOut), 
            s.emptyLimit
        );
        console.log('netPtOut - sUSDe: ', netPtOut);

        uint discountedPT = _calculateDiscountPT();
        //^^ now that i have the discounted PT, get the USDC from rebuyPT() below,
        //mint ozUSD and send it to the user while locking the USDC as backup

        s.ozUSD.mint(receiver_, sUSDeOut);
    }


     function rebuyPT(uint amountInUSDC_) external {
        IERC20 sUSDe_PT_26SEP = IERC20(0x6c9f097e044506712B58EAC670c9a5fd4BCceF13);

       s.USDC.transferFrom(msg.sender, address(this), amountInUSDC_);

       uint balancePT = sUSDe_PT_26SEP.balanceOf(address(this));
       sUSDe_PT_26SEP.transfer(msg.sender, balancePT);

    }


    function redeem(uint amount_, address receiver_) external {
        uint minTokenOut = 0;
        address sUSDe_PT_26SEP = 0x6c9f097e044506712B58EAC670c9a5fd4BCceF13;

        console.log('sender: ', msg.sender);
        console.log('PT bal oz - pre swap: ', IERC20(sUSDe_PT_26SEP).balanceOf(address(this)));
        console.log('sUSDe oz - pre swap: ', s.sUSDe.balanceOf(address(this)));
        console.log('');

        // bytes memory data = abi.encodeWithSelector(
        //     s.sUSDe.approve.selector, address(s.pendleRouter), type(uint).max
        // );

        // (bool s,) = sUSDe_PT_26SEP.delegatecall(data);
        // require(s, 'fff');
        // sUSDe_PT_26SEP.functionDelegateCall(data);

        // bytes memory data = abi.encodeWithSelector(
        //     MyPendleRouter.swapExactPtForToken.selector,
        //     address(this), 
        //     address(s.sUSDeMarket), 
        //     amount_, 
        //     createTokenOutputStruct(address(s.sUSDe), minTokenOut), 
        //     s.emptyLimit
        // );

        // (s,) = address(s.pendleRouter).delegatecall(data);
        // require(s, 'ggg');

        // address(s.pendleRouter).functionDelegateCall(data);

        (uint256 netTokenOut,,) = s.pendleRouter.swapExactPtForToken(
            address(this), 
            address(s.sUSDeMarket), 
            amount_, 
            createTokenOutputStruct(address(s.sUSDe), minTokenOut), 
            s.emptyLimit
        );

        // console.log('netTokenOut sUSDe: ', 1);
        // console.log(string('netTokenOut sUSDe: '), uint(1));
        console.log('netTokenOut sUSDe: ', netTokenOut);
        console.log('PT bal oz - post swap: ', IERC20(sUSDe_PT_26SEP).balanceOf(address(this)));
        console.log('sUSDe oz - post swap: ', s.sUSDe.balanceOf(address(this)));
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


    function _calculateDiscountPT() private returns(uint) {
        uint balancePT = s.pendlePT.balanceOf(address(this));
        uint percentage = 500; //5%
        uint discount = (percentage * balancePT) / 10_000;
        uint discountedPT = balancePT - discount;
        return discountedPT;
    }

}