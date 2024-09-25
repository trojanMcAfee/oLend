// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import {UserAccountData, BalancerSwapConfig, Tokens} from "../AppStorage.sol";
import {IPool} from "@aave/core-v3/contracts/interfaces/IPool.sol";
// import {LimitOrderData} from "@pendle/core-v2/contracts/interfaces/IPAllActionTypeV3.sol";
// import {LimitOrderData, ApproxParams} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {StructGen} from "../StructGen.sol";
import {SafeERC20} from "@openzeppelin/contracts/token/ERC20/utils/SafeERC20.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "../interfaces/IERC20.sol";
import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
// import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
// import {ISwapRouter} from "@uniswap/v3-periphery/contracts/interfaces/ISwapRouter.sol";

import {IPActionSwapPTV3} from "@pendle/core-v2/contracts/interfaces/IPActionSwapPTV3.sol";
import {TokenOutput, LimitOrderData} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {InternalAccount} from "../InternalAccount.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {IVault, IAsset} from "../interfaces/IBalancer.sol";
import {ozTrading} from "../periphery/ozTrading.sol";
import {HelpersLib} from "../libraries/HelpersLib.sol";

import "forge-std/console.sol";



contract ozMinter is ozTrading {

    using SafeERC20 for IERC20;
    using Address for address;
    using FixedPointMathLib for uint;
    using HelpersLib for address;

    event NewAccountCreated(address account);


    function lend(uint amountIn_, bool isETH_) external payable checkAavePool {      
        InternalAccount account = s.internalAccounts[msg.sender];

        if (address(s.internalAccounts[msg.sender]) == address(0)) {
            account = _createUser();
            emit NewAccountCreated(address(account));
        }

        if (isETH_) {
            account.depositInAave{value: msg.value}();
            return;
        }
    }


    function getUserAccountData(address user_) external view returns(UserAccountData memory userData) {
        InternalAccount account = s.internalAccounts[user_];
        
        (
            uint totalCollateralBase,
            uint totalDebtBase,
            uint availableBorrowsBase,
            uint currentLiquidationThreshold,
            uint ltv,
            uint healthFactor
        ) = s.aavePool.getUserAccountData(address(account));

        userData = UserAccountData(
            totalCollateralBase,
            totalDebtBase,
            _applyDiscount(availableBorrowsBase), //apply this to the ones that need to be applied
            currentLiquidationThreshold,
            ltv,
            healthFactor
        );
    }



    function borrow(uint amount_, address receiver_) external {
        InternalAccount internalAccount = s.internalAccounts[msg.sender];
        uint revertedAmount = s.relayer.borrowInternal(amount_, receiver_, address(internalAccount));

        uint minTokenOut = 0;

        //using uniswap here for simplicity atm. This would need to be fixed for a more efficient method. 
        uint sUSDeOut = _swapUni(
            address(s.USDC), 
            address(s.sUSDe), 
            address(this), 
            revertedAmount, 
            minTokenOut
        );
      
        // s.USDC.safeApprove(address(s.pendleRouter), amount_); <---- this is not working - 2nd instance of issue - prob diff IERC20 versions
        s.sUSDe.approve(address(s.pendleRouter), sUSDeOut);

        uint minPTout = 0;
      
        (uint256 netPtOut,,) = s.pendleRouter.swapExactTokenForPt(
            address(this), 
            address(s.sUSDeMarket), 
            minPTout, 
            s.defaultApprox, //check StructGen.sol for a more gas-efficient impl of this
            address(s.sUSDe).createTokenInputStruct(sUSDeOut, s.emptySwap), 
            s.emptyLimit
        );

        console.log('netPtOut ***** - owned by oz: ', netPtOut);
        uint internalAccountDebtUSDC = s.aaveVariableDebtUSDC.balanceOf(address(internalAccount));
        console.log('usdc debt - int acc: ', internalAccountDebtUSDC);

        s.ozUSD.mint(receiver_, internalAccountDebtUSDC);

        // uint discountedPT = _calculateDiscountPT();
        // s.openOrders.push(discountedPT);
    }
    
    function finishBorrow(address receiver_) external {
        uint balanceUSDC = s.USDC.balanceOf(address(this));
        s.ozUSD.mint(receiver_, balanceUSDC);
    }


     function rebuyPT(uint amountInUSDC_) external { //do this with a signature instead of approve()
        require(s.openOrders.length > 0, 'rebuyPT: error');
        
        s.USDC.transferFrom(msg.sender, address(this), amountInUSDC_);

        uint balancePT = s.pendlePT.balanceOf(address(this));
        s.pendlePT.transfer(msg.sender, balancePT);
}



    function performRedemption(uint amount_, address owner_, address receiver_, Tokens token_) external returns(uint) { 
        // uint amountOut;

        uint minTokenOut = 0;

        (uint256 amountYieldTokenOut,,) = s.pendleRouter.swapExactPtForToken(
            address(this), 
            address(s.sUSDeMarket), 
            s.pendlePT.balanceOf(address(this)), 
            address(s.sUSDe).createTokenOutputStruct(minTokenOut, s.emptySwap), 
            s.emptyLimit
        );

        //------------
        //Before the swap, gotta do a triage offchain using these functions below in order to guarantee that
        //the most liquid pools are always used
        // address[] memory pools2 = s.curveMetaRegistry.find_pools_for_coins(address(s.sUSDe), 0x83F20F44975D03b1b09e64809B757c47f942BEeA);
        // console.log('l: ', pools2.length);
        // console.log('');
        //------------


        (
            address[11] memory route, 
            uint[5][5] memory swap_params,
            address[5] memory pools
        ) = _createCrvSwap(_getTokenOut(token_));

        s.sUSDe.approve(address(s.curveRouter), amountYieldTokenOut);

        uint amountOut = s.curveRouter.exchange(
            route, 
            swap_params, 
            amountYieldTokenOut, 
            minTokenOut, 
            pools, 
            address(this)
        ); 
        console.log('frax bal oz - post crv swap - not 0: ', s.FRAX.balanceOf(address(this)));

        s.FRAX.transfer(receiver_, amountOut);
        

        //balancer impl
        if (token_ == Tokens.WETH) {

            // console.logUint(1);
            // (
            //     address[11] memory route, 
            //     uint[5][5] memory swap_params,
            //     address[5] memory pools
            // ) = _createCrvSwap(address(s.WETH));

            // console.logUint(2);

            // s.curveRouter.exchange(route, swap_params, amountYieldTokenOut, minTokenOut, pools, address(this)); 
            // console.log('weth bal oz - post crv swap - not 0: ', s.WETH.balanceOf(address(this)));

            revert('here9');




            amountOut =  _swapBalancer(
                address(s.sUSDe), 
                address(s.WETH), 
                amountYieldTokenOut, //amountIn
                minTokenOut,
                true
            );

            console.log('amountOut *****: ', amountOut);
            console.log('WETH oz - post batch - not 0: ', s.WETH.balanceOf(address(this)));

            s.WETH.transfer(receiver_, amountOut);
        } else if (token_ == Tokens.USDC) {

        }


        // console.log('sUSDe oz - post withdraw - 0: ', s.sUSDe.balanceOf(address(this)));
        // console.log('USDe oz - post withdraw - not 0: ', s.USDe.balanceOf(address(this)));
        return amountOut;
    }



    //************* */

    

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


    /**
     * Current implementation hardcodes an extra 10 bps (0.1%) on the discount that's
     * available for borrowing (0.1% less borrowable amount from Aave).
     * 
     * Once the order book is properly set up, an algorithm for this function must be created
     * to better reflect the relationship between the value of PT in assetRate (USDC, USDe)
     * the applied discount to PT repurchase (currently at 5%), and the original availableBorrowsBase
     * from Aave when lending user's tokens.
     *
     * availableBorrowsBase's is almost the same as PT value in assetRate. 
     */
    function _applyDiscount(uint singleState_) private view returns(uint) {
        return (singleState_ - (s.ptDiscount + 10).mulDivDown(singleState_, 10_000)) / 1e2;
    }


    function _getTokenOut(Tokens token_) private view returns(address tokenOut) {
        if (token_ == Tokens.sDAI) {
            tokenOut = address(s.sDAI);
        } else if (token_ == Tokens.FRAX) {
            tokenOut = address(s.FRAX);
        }
    }


}