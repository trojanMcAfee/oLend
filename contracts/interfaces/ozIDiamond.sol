// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDiamondCut} from "./IDiamondCut.sol";


interface ozIDiamond {
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    function lend(uint amountIn_, bool isETH_) external payable;
    function borrow(uint amount_, address receiver_) external;
    function redeem(uint amount_, address receiver_) external;
    function rebuyPT(uint amountInUSDC_) external;
    function quotePT() external view returns(uint);
    function finishBorrow(address receiver_) external;
}
