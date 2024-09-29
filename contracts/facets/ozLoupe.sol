// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {State} from "../State.sol";
import {UserAccountData} from "../AppStorage.sol";
import {DiamondLoupeFacet} from "./DiamondLoupeFacet.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";


contract ozLoupe is State, DiamondLoupeFacet {

    using FixedPointMathLib for uint;

    // function getUserInternalAccount(address user_) external view returns(address) {
    //     return s.internalAccounts[user_];
    // }


    function getUserAccountData(address user_) external view returns(UserAccountData memory userData) {
        address account = address(s.internalAccounts[user_]);
        
        (
            uint totalCollateralBase,
            uint totalDebtBase,
            uint availableBorrowsBase,
            uint currentLiquidationThreshold,
            uint ltv,
            uint healthFactor
        ) = s.aavePool.getUserAccountData(account);

        userData = UserAccountData(
            account,
            totalCollateralBase,
            totalDebtBase,
            _applyDiscount(availableBorrowsBase), //apply this to the ones that need to be applied
            currentLiquidationThreshold,
            ltv,
            healthFactor
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
    function _applyDiscount(uint singleState_) private view returns(uint) {
        return (singleState_ - (s.ptDiscount + 10).mulDivDown(singleState_, 10_000)) / 1e2;
    }

}