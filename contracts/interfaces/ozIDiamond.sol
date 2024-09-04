// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;

import {IDiamondCut} from "./IDiamondCut.sol";


interface ozIDiamond {
    function diamondCut(
        IDiamondCut.FacetCut[] calldata _diamondCut,
        address _init,
        bytes calldata _calldata
    ) external;

    function lend(bool isETH_) external payable;
    function borrow(uint amount_) external returns(uint);
}
