// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.0;


import {UserAccountData} from "../AppStorage.sol";
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
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {Modifiers} from "../Modifiers.sol";
import {InternalAccount} from "../InternalAccount.sol";

import "forge-std/console.sol";


contract ozMinter is Modifiers {

    using SafeERC20 for IERC20;
    using Address for address;

    event NewAccountCreated(address account);


    function lend(uint amountIn_, bool isETH_) external payable checkAavePool {      
        InternalAccount account = s.internalAccounts[msg.sender];

        if (address(s.internalAccounts[msg.sender]) == address(0)) {
            account = _createUser();
            console.log('InternalAccount: ', address(account));
            emit NewAccountCreated(address(account));
        }

        if (isETH_) {
            account.depositInAave{value: msg.value}();
            return;

            // s.aaveGW.depositETH{value: msg.value}(s.aavePool, address(this), 0);
            // return;
        }
    }


    function getUserAccountData(address user_) public view returns(UserAccountData memory) {

    }
   

    function borrow(uint amount_, address receiver_) external {
        InternalAccount account = s.internalAccounts[msg.sender];
        // account.borrowInternal(amount_, receiver_);
        s.relayer.borrowInternal(amount_, receiver_, address(account));
    }


    function borrow2(uint amount_, address receiver_) external {
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
        // console.log('sUSDeOut: ', sUSDeOut);


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
        // console.log('netPtOut - sUSDe: ', netPtOut);

        uint discountedPT = _calculateDiscountPT();
        // console.log('discountedPT: ', discountedPT);

        s.openOrders.push(discountedPT);

        // s.ozUSD.mint(receiver_, sUSDeOut);
    }
    
    function finishBorrow(address receiver_) external {
        uint balanceUSDC = s.USDC.balanceOf(address(this));
        // console.log('balanceUSDC - in finishBorrow - not 0: ', balanceUSDC);
        s.ozUSD.mint(receiver_, balanceUSDC);
    }


     function rebuyPT(uint amountInUSDC_) external {
        require(s.openOrders.length > 0, 'rebuyPT: error');
        
        s.USDC.transferFrom(msg.sender, address(this), amountInUSDC_);

        uint balancePT = s.pendlePT.balanceOf(address(this));
        s.pendlePT.transfer(msg.sender, balancePT);
    }


    //This redeems PT for token, which seems not needed in this system, since the redemptions would be
    //from ozUSD to token (prob done in the ERC20 contract)
    function redeem(uint amount_, address receiver_) external { 
        uint minTokenOut = 0;
        address sUSDe_PT_26SEP = 0x6c9f097e044506712B58EAC670c9a5fd4BCceF13;

        console.log('sender: ', msg.sender);
        console.log('PT bal oz - pre swap: ', s.pendlePT.balanceOf(address(this)));
        console.log('sUSDe oz - pre swap: ', s.sUSDe.balanceOf(address(this)));
        console.log('');


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
        bytes memory data = abi.encodeWithSelector(ozIDiamond.quotePT.selector);
        data = s.OZ.functionDelegateCall(data);
        return abi.decode(data, (uint));
    }


    function _createUser() private returns(InternalAccount) {
        InternalAccount account = new InternalAccount(address(s.relayer));
        s.internalAccounts[msg.sender] = account;
        return account;
    }


}