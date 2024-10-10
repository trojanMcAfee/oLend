// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDiamondCut} from "./IDiamondCut.sol";
import {UserAccountData, Tokens} from "../AppStorage.sol";


interface ozIDiamond {
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    function lend(uint amountIn, address tokenIn, address receiver) external payable returns(uint);
    // function lend(uint amountIn_, address tokenIn_) external payable;
    function borrow(uint amount_, address receiver_) external;
    function performRedemption(
        uint amount_, 
        uint minAmountOut_, 
        address owner_, 
        address receiver_, 
        Tokens token_
    ) external returns(uint);
    function quotePT() external view returns(uint);
    function getUserAccountData(address user_) external view returns(UserAccountData memory userData);
    function getBorrowingRates(address token_, bool formatted_) external view returns(uint);
    function getSupplyRates(address token_, bool formatted_) external view returns(uint, uint);

    function getVariableBorrowAPY() external view returns(uint);
    function getNetAPY(address token) external view returns(uint);
    function getInternalSupplyRate() external view returns(uint);

    function getExchangeRate() external view returns(uint);
}
