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
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {IVault, IAsset} from "../interfaces/IBalancer.sol";

import "forge-std/console.sol";


struct UserCooldown {
        uint104 cooldownEnd;
        uint152 underlyingAmount;
    }

interface My {
    function unstake(address receiver) external;
    function cooldowns(address) external view returns(UserCooldown memory);
}


contract ozMinter is Modifiers {

    using SafeERC20 for IERC20;
    using Address for address;
    using FixedPointMathLib for uint;

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
            s.defaultApprox, 
            createTokenInputStruct(address(s.sUSDe), sUSDeOut), 
            s.emptyLimit
        );

        console.log('netPtOut ***** - owned by oz: ', netPtOut);
        // IERC20 aaveVariableDebtUSDC = IERC20(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
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

    // 1 ozUSD --- n PT --- m SY


    //This redeems PT for token, which seems not needed in this system, since the redemptions would be
    //from ozUSDtoken to token (prob done in the ERC20 contract)
    function redeem(uint amount_, address owner_, address receiver_, bool isETH_) external { 
        uint minTokenOut = 0;

        console.log('sender: ', msg.sender);
        console.log('PT bal OZ: ', s.pendlePT.balanceOf(address(this)));

        (uint256 netTokenOut,,) = s.pendleRouter.swapExactPtForToken(
            address(this), 
            address(s.sUSDeMarket), 
            s.pendlePT.balanceOf(address(this)), 
            createTokenOutputStruct(address(s.sUSDe), minTokenOut), 
            s.emptyLimit
        );

        console.log('netTokenOut sUSDe: ', netTokenOut);
        console.log('PT bal oz - post swap: ', s.pendlePT.balanceOf(address(this)));
        console.log('USDe oz - post swap - 0: ', s.USDe.balanceOf(address(this)));
        console.log('sUSDe oz - post swap - not 0: ', s.sUSDe.balanceOf(address(this)));
        console.log('');

        if (isETH_) {
            _swapBalancer(address(s.sUSDe), tokenOut_, amountIn_, minAmountOut_);
            //^ finish this to swap from sUSDe to wstETH, and then unstake for getting ETH
        }


        console.log('sUSDe oz - post withdraw - 0: ', s.sUSDe.balanceOf(address(this)));
        console.log('USDe oz - post withdraw - not 0: ', s.USDe.balanceOf(address(this)));

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
        uint24 poolFee = 500;

        ISwapRouter.ExactInputParams memory params =
            ISwapRouter.ExactInputParams({
                path: abi.encodePacked(tokenIn_, poolFee, address(s.USDT), poolFee, tokenOut_), //500 -> 0.05
                recipient: receiver_,
                deadline: block.timestamp,
                amountIn: amountIn_,
                amountOutMinimum: minAmountOut_
            });

        return swapRouterUni.exactInput(params);
    }

    function _swapBalancer( 
        address tokenIn_, 
        address tokenOut_, 
        uint amountIn_,
        uint minAmountOut_
    ) private returns(uint amountOut) {

        IVault.SingleSwap memory singleSwap = IVault.SingleSwap({
            poolId: balancerPoolWstETHsUSDe.getPoolId(),
            kind: IVault.SwapKind.GIVEN_IN,
            assetIn: IAsset(tokenIn_),
            assetOut: IAsset(tokenOut_),
            amount: amountIn_,
            userData: new bytes(0)
        });

        IVault.FundManagement memory funds = IVault.FundManagement({
            sender: address(this),
            fromInternalBalance: false, 
            recipient: payable(address(this)),
            toInternalBalance: false
        });

        IERC20(tokenIn_).approve(address(s.balancerVault), singleSwap.amount);
        // IERC20(tokenIn_).safeApprove(s.balancerVault, singleSwap.amount); //use this in prod - for safeApprove to work, allowance has to be reset to 0 on a mock. Can't be done on mockCall()
        amountOut = _executeSwap(singleSwap, funds, minAmountOut_, block.timestamp);
    }

    function _executeSwap(
        IVault.SingleSwap memory singleSwap_,
        IVault.FundManagement memory funds_,
        uint minAmountOut_,
        uint blockStamp_
    ) private returns(uint) 
    {        
        try s.balancerVault.swap(singleSwap_, funds_, minAmountOut_, blockStamp_) returns(uint amountOut) {
            if (amountOut == 0) revert('my 1');
            return amountOut;
        } catch Error(string memory reason) {
            revert('error in _executeSwap()');
            // if (Helpers.compareStrings(reason, 'BAL#507')) {
            //     revert('my 2');
            // } else {
            //     revert(reason);
            // }
        }
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


}