// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ERC20Upgradeable} from "@openzeppelin/contracts-upgradeable/token/ERC20/ERC20Upgradeable.sol";
import {Tokens} from "./AppStorage.sol";
import {ozIDiamond} from "./interfaces/ozIDiamond.sol";


contract ozUSDtoken is ERC20Upgradeable {

    ozIDiamond public immutable OZ;

    constructor(address ozDiamond_) {
        OZ = ozIDiamond(ozDiamond_); 
    }
    

    function mint(address account_, uint amount_) external { //put a onlyAuth mod
        _mint(account_, amount_);
    }

    function burn(address account_, uint amount_) external { //put onlyAuth mod
        _burn(account_, amount_);
    }

    function initialize(string memory name_, string memory symbol_) external initializer {
        __ERC20_init(name_, symbol_);
    }

    function redeem(
        uint amount_, 
        address account_, 
        address receiver_, 
        Tokens token_
    ) external returns(uint) {
        _burn(account_, amount_);

        uint amountOut = OZ.performRedemption(
            amount_, 
            account_, 
            receiver_, 
            token_
        );

        return amountOut;
    }

}