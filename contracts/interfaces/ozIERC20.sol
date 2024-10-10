// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {IERC20} from "./IERC20.sol";


interface ozIERC20 is IERC20 {
    function rebase() external;
    function redeem(
        uint amountIn, 
        address owner, 
        address receiver,
        address tokenOut
    ) external returns(uint);

    //put an IERC4626 interfaces here instead (inherited)
    function deposit(uint256 assets, address receiver) external returns (uint256 shares);
}