// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
import {OZError03, OZError04} from "../OZErrors.sol";

import "forge-std/console.sol";


contract ozUSDCtoken is ERC20 {

    ozIDiamond OZ;
    uint scalingFactor = 1e18;
    uint lastRebaseTime;
    uint rebaseInterval = 24 hours;
    uint previousRatePT;

    event Rebase(uint indexed newScalingFactor, uint indexed rebaseTime);


    constructor(
        string memory name_, 
        string memory symbol_,
        address oz_
    ) ERC20(name_, symbol_) {
        require(oz_ != address(0), 'ozUSDCtoken: oz_ is zero');

        OZ = ozIDiamond(oz_);
        lastRebaseTime = block.timestamp;
    }


    //put an initialized() modifier here
    function setInitialRate() external {
        previousRatePT = OZ.getInternalSupplyRate();
    }

    function mint(address account_, uint amount_) external { //put an onlyAuth mod 
        _mint(account_, amount_);
    }

    function balanceOf(address account_) public view override returns(uint) {
        uint underlyingBalance = super.balanceOf(account_);
        return (underlyingBalance * scalingFactor) / 1e18;
    }


    function redeem(uint amountIn_, address owner_, address receiver_) external returns(uint) {
        uint underlyingAmount = (amountIn_ * 1e18) / scalingFactor;
        _burn(owner_, underlyingAmount);

    }



    //this should be managed in a way from OZ (pref ozMinter)
    function rebase() public {
        if (block.timestamp < lastRebaseTime + rebaseInterval) revert OZError03();

        uint currentRatePT = OZ.getInternalSupplyRate();
        if (currentRatePT < previousRatePT) revert OZError04();

        uint growthRate = ((currentRatePT - previousRatePT) * 1e18) / previousRatePT;
        scalingFactor = (scalingFactor * (1e18 + growthRate)) / 1e18;

        previousRatePT = currentRatePT;
        lastRebaseTime = block.timestamp;

        emit Rebase(scalingFactor, lastRebaseTime);
    }

}