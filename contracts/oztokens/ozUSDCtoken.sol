// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";

import "forge-std/console.sol";


contract ozUSDCtoken is ERC20 {

    ozIDiamond OZ;

    constructor(
        string memory name_, 
        string memory symbol_,
        address oz_
    ) ERC20(name_, symbol_) {
        require(oz_ != address(0), 'ozUSDCtoken: oz_ is zero');
        OZ = ozIDiamond(oz_);
    }


    function mint(address account_, uint amount_) external {
        _mint(account_, amount_);
    }

    function balanceOf(address account_) public view override returns(uint) {
        (, uint pendleFixedAPY) = OZ.getSupplyRates(address(0), false);
        console.log('pendleFixedAPY ****: ', pendleFixedAPY);
        
        uint ratePT = OZ.getInternalSupplyRate();
        console.log('ratePT: ', ratePT);

        return super.balanceOf(account_);
    }

}