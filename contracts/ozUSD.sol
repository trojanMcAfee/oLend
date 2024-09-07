// SPDX-License-Identifier: MIT
pragma solidity 0.8.26;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";


contract ozUSD is ERC20Upgradeable {

    constructor() {
        _disableInitializers();
    }
    

    function mint(address account_, uint amount_) external { //put a onlyAuth mod
        _mint(account_, amount_);
    }

    function initialize(string memory name_, string memory symbol_) external initializer {
        __ERC20_init(name_, symbol_);
    }

}