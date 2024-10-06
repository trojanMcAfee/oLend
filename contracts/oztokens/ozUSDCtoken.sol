// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";


contract ozUSDCtoken is ERC20 {

    constructor(string memory name_, string memory symbol_) ERC20(name_, symbol_) {}


    function mint(address account_, uint256 amount_) external {
        _mint(account_, amount_);
    }

}