// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity ^0.8.0;


import {UserAccountData, BalancerSwapConfig, Tokens, CrvSwapConfig, Model} from "../AppStorage.sol";
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
import {DataTypes} from "@aave/core-v3/contracts/protocol/libraries/types/DataTypes.sol";
import {Address} from "@openzeppelin/contracts/utils/Address.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {InternalAccount} from "../InternalAccount.sol";
import {IVault, IAsset} from "../interfaces/IBalancer.sol";
import {ozTrading} from "../periphery/ozTrading.sol";
import {HelpersLib} from "../libraries/HelpersLib.sol";
import "../OZErrors.sol";

import "forge-std/console.sol";



contract ozMinter is ozTrading {

    using SafeERC20 for IERC20;
    using Address for address;
    // using FixedPointMathLib for uint;
    using HelpersLib for address;

    event NewAccountCreated(address account);
    event NewAccountDataState(
        uint totalCollateralBase,
        uint16 ltv,
        uint currentLiquidationThreshold,
        uint healthFactor
    );


    function lend(uint amountIn_, address tokenIn_) external payable checkAavePool {      
        if (tokenIn_ == s.ETH) if (amountIn_ != msg.value) revert OZError02(amountIn_, msg.value);
        if (!s.authTokens[tokenIn_]) revert OZError01(tokenIn_);

        uint msgValue;
        InternalAccount account = InternalAccount(s.usersAccountData[msg.sender].internalAccount);

        if (address(account) == address(0)) {
            account = new InternalAccount(
                address(s.relayer),
                s.ETH,
                address(s.aaveGW),
                address(s.aavePool),
                address(s.aaveVariableDebtUSDCDelegate)
            );
            emit NewAccountCreated(address(account));
        }

        if (tokenIn_ != s.ETH) {
            IERC20(tokenIn_).transferFrom(msg.sender, address(account), amountIn_);
            msgValue = 0;
        } else {
            msgValue = msg.value;
        }

        _setUserAccountData(tokenIn_, msg.sender, address(account), amountIn_);

        account.buyPT(amountIn_, address(account), tokenIn_);
        s.ozTokens[tokenIn_].mint(msg.sender, amountIn_);

        // account.depositInAave{value: msgValue}(amountIn_, tokenIn_);
        // s.relayer.buyPT(amountIn_, address(account), tokenIn_);
    }

    
    function lend2(uint amountIn_, address tokenIn_) external payable checkAavePool {      
        if (tokenIn_ == s.ETH) if (amountIn_ != msg.value) revert OZError02(amountIn_, msg.value);
        if (!s.authTokens[tokenIn_]) revert OZError01(tokenIn_);

        uint msgValue;
        InternalAccount account = s.internalAccounts[msg.sender];

        if (address(account) == address(0)) {
            account = _createUser();
            emit NewAccountCreated(address(account));
        }

        if (tokenIn_ != s.ETH) {
            IERC20(tokenIn_).transferFrom(msg.sender, address(account), amountIn_);
            msgValue = 0;
        } else {
            msgValue = msg.value;
        }

        account.depositInAave{value: msgValue}(amountIn_, tokenIn_);
    }



    function borrow(uint amount_, address receiver_) external {
        InternalAccount internalAccount = s.internalAccounts[msg.sender];
        s.relayer.borrowInternal(amount_, receiver_, address(internalAccount));

        uint minTokenOut = 0;

        //using uniswap here for simplicity atm. This would need to be fixed for a more efficient method. 
        uint sUSDeOut = _swapUni(
            address(s.USDC), 
            address(s.sUSDe), 
            address(this), 
            amount_, 
            minTokenOut
        );
      
        // s.USDC.safeApprove(address(s.pendleRouter), amount_); <---- this is not working - 2nd instance of issue - prob diff IERC20 versions
        s.sUSDe.approve(address(s.pendleRouter), sUSDeOut);

        uint minPTout = 0;
        console.log('sUSDeOut being swapped for PT - in borrow(): ', sUSDeOut);
      
        //the PT out should go to the internalAccount instead of OZ (modify this)
        (uint256 netPtOut,,) = s.pendleRouter.swapExactTokenForPt(
            address(this), 
            address(s.sUSDeMarket), 
            minPTout, 
            s.defaultApprox, //check StructGen.sol for a more gas-efficient impl of this
            address(s.sUSDe).createTokenInputStruct(sUSDeOut, s.emptySwap), 
            s.emptyLimit
        );

        console.log('netPtOut after PT swap: ', netPtOut);

        uint internalAccountDebtUSDC = s.aaveVariableDebtUSDC.balanceOf(address(internalAccount));
        s.ozUSD.mint(receiver_, internalAccountDebtUSDC);
    }
    




    function performRedemption(
        uint amount_, //it should be s.pendlePT.balanceOf(address(this)) from below
        uint minAmountOut_,
        address owner_, 
        address receiver_, 
        Tokens token_
    ) external returns(uint) { 
    
        (uint256 amountYieldTokenOut,,) = s.pendleRouter.swapExactPtForToken(
            address(this), 
            address(s.sUSDeMarket), 
            s.pendlePT.balanceOf(address(this)), //don't use balanceOf()
            address(s.sUSDe).createTokenOutputStruct(minAmountOut_, s.emptySwap), 
            s.emptyLimit
        );

        if (token_ == Tokens.sUSDe) {
            s.sUSDe.transfer(receiver_, amountYieldTokenOut);
            return amountYieldTokenOut;
        }
        
        CrvSwapConfig memory swapConfig = _getCrvSwap(token_);

        s.sUSDe.approve(address(s.curveRouter), amountYieldTokenOut); 

        uint amountOut = s.curveRouter.exchange(
            swapConfig.route, 
            swapConfig.swap_params, 
            amountYieldTokenOut, 
            minAmountOut_, 
            swapConfig.pools, 
            receiver_
        ); 

        //balancer impl (in case Curve is not possible)
        // amountOut =  _swapBalancer(
        //     address(s.sUSDe), 
        //     address(s.WETH), 
        //     amountYieldTokenOut,
        //     minAmountOut_,
        //     true
        // );
    
        return amountOut;
    }



    //************* */
    function _createUser() private returns(InternalAccount) {
        InternalAccount account = new InternalAccount(
            address(s.relayer),
            s.ETH,
            address(s.aaveGW),
            address(s.aavePool),
            address(s.aaveVariableDebtUSDCDelegate)
        );
        // s.internalAccounts[msg.sender] = account;
        return account;
    }

    function _setUserAccountData(
        address lentToken_, 
        address user_, 
        address intAcc_, 
        uint collateralIn_
    ) private {
        UserAccountData storage userData = s.usersAccountData[user_];

        if (lentToken_ == address(s.USDC)) {
            userData.ltv = s.interestRateModels[Model.STABLE].ltv;
            userData.currentLiquidationThreshold = s.interestRateModels[Model.STABLE].liqTreshold;
        }
    
        userData.internalAccount = intAcc_;
        userData.totalCollateralBase += collateralIn_;
        userData.healthFactor = type(uint).max;
        
        //Refactor this for gas ops since it's reading from storage constantly
        emit NewAccountDataState(
            userData.totalCollateralBase,
            userData.ltv,
            userData.currentLiquidationThreshold,
            userData.healthFactor
        );
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
    // function _applyDiscount(uint singleState_) private view returns(uint) {
    //     return (singleState_ - (s.ptDiscount + 10).mulDivDown(singleState_, 10_000)) / 1e2;
    // }


}