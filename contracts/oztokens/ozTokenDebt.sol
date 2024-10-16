// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ERC20} from "@contracts/ERC20.sol";
import {IERC20} from "@contracts/interfaces/IERC20.sol";
import {OZError08} from "@contracts/OZErrors.sol";


contract ozTokenDebt is ERC20 {


    constructor(
        string memory name_,
        string memory symbol_,
        address underlying_
    ) ERC20(name_, symbol_, IERC20(underlying_).decimals()) {}


    function transfer(address, uint256) public override returns (bool) {
        revert OZError08();
    }

    // function allowance(address, address) external view override returns (uint256) {
    //     revert OZError08();
    // }

    function approve(address, uint256) public override returns (bool) {
        revert OZError08();
    }

    function transferFrom(
    address,
    address,
    uint256
  ) public override returns (bool) {
    revert OZError08();
  }

  function increaseAllowance(address, uint256) external returns (bool) {
    revert OZError08();
  }

  function decreaseAllowance(address, uint256) external returns (bool) {
    revert OZError08();
  }

}