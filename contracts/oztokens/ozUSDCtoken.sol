// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


// import {ERC20} from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import {ERC20} from "../ERC20.sol";
import {ozIDiamond} from "../interfaces/ozIDiamond.sol";
// import {IERC20} from "../interfaces/IERC20.sol";
import {IERC20} from "@openzeppelin/contracts/interfaces/IERC20.sol";
import {OZError03, OZError04} from "../OZErrors.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {InternalAccount} from "../InternalAccount.sol";
import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";
import {FixedPointMathLib} from "solmate/src/utils/FixedPointMathLib.sol";
import {ERC4626} from "../ERC4626.sol";
// import {ERC4626} from "solady/src/tokens/ERC4626.sol";
// import {ERC4626} from "@openzeppelin/contracts/token/ERC20/extensions/ERC4626.sol";

import "forge-std/console.sol";


contract ozUSDCtoken is ERC4626 {

    ozIDiamond OZ;
    uint scalingFactor = 1e18;
    uint lastRebaseTime;
    uint rebaseInterval = 24 hours;
    uint previousRatePT;

    uint private _totalAssets;

    // mapping(address internalAccount => uint balancePT) intAccBalancePT;;

    IPMarket sUSDeMarket = IPMarket(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);
    IERC20 USDC = IERC20(0xA0b86991c6218b36c1d19D4a2e9Eb0cE3606eB48);
    IERC20 sUSDe_PT_26SEP = IERC20(0x6c9f097e044506712B58EAC670c9a5fd4BCceF13);

    using PendlePYOracleLib for IPMarket;
    using FixedPointMathLib for uint;

    event Rebase(uint indexed newScalingFactor, uint indexed rebaseTime);


    constructor(
        string memory name_, 
        string memory symbol_,
        address oz_,
        address underlying_
    ) ERC4626(ERC20(underlying_), name_, symbol_) {
        require(oz_ != address(0), 'ozUSDCtoken: oz_ is zero');

        OZ = ozIDiamond(oz_);
        lastRebaseTime = block.timestamp;
    }


    //put an initialized() modifier here
    function setInitialRate() external {
        previousRatePT = OZ.getInternalSupplyRate();
    }

    // function mint(address account_, uint amount_) external { //put an onlyAuth mod 
    //     // _mint(account_, amount_);
    //     uint shares = deposit(amount_, account_);
    //     console.log('shares *****: ', shares);
    //     // revert('here2');
    // }

    //put an onlyAuth mod
    function deposit(uint256 assets, address receiver) public override returns (uint256 shares) {
        require((shares = previewDeposit(assets)) != 0, "ZERO_SHARES");

        _totalAssets += assets;

        _mint(receiver, shares);

        emit Deposit(msg.sender, receiver, assets, shares);
    }

    function balanceOf(address account) public view override returns(uint256) {
        uint underlyingBalance = super.balanceOf(account);

        console.log('account: ', account);
        console.log('underlyingBalance in balanceOf: ', underlyingBalance);


        return (underlyingBalance * scalingFactor) / 1e18;
    }


    function redeem(
        uint amountIn_, 
        address owner_, 
        address receiver_,
        address tokenOut_
    ) external returns(uint) {
        console.log('');

        uint underlyingAmount = amountIn_.mulDivUp(1e18, scalingFactor);
        uint totalUserUnderlyingAmount = balanceOf(owner_).mulDivUp(1e18, scalingFactor);

        uint userShares = convertToShares(underlyingAmount);
        uint totalUserShares = convertToShares(totalUserUnderlyingAmount);
        
        address intAcc = OZ.getUserAccountData(owner_).internalAccount;
        uint totalUserPT = sUSDe_PT_26SEP.balanceOf(intAcc);
        // uint totalUserPT = OZ.getBalancePT(owner_);

        console.log('amountIn_: ', amountIn_);
        console.log('balanceOf(owner_): ', balanceOf(owner_));
        console.log('underlyingAmount: ', underlyingAmount);
        console.log('userShares: ', userShares);
        console.log('totalUserShares: ', totalUserShares);
        console.log('totalUserPT: ', totalUserPT);

        uint amountInPT = userShares.mulDivDown(totalUserPT, totalUserShares);
        console.log('amountInPT %%%%%%: ', amountInPT);

        revert('here11');
        
        // totalUserShares --- s.intAccBalancePT[owner_]
        // userShares ---- x

        // console.log('--- in redeem() - ozUSDCtoken ---');
        // console.log('underlyingAmount: ', underlyingAmount);
        // console.log('amountIn_: ', amountIn_);
        // console.log('convertToShares with underlyingAmount ****: ', convertToShares(underlyingAmount));
        // console.log('convertToShares with amountIn_: ', convertToShares(amountIn_));

        _burn(owner_, underlyingAmount);

        // revert('here77');

        InternalAccount account = InternalAccount(OZ.getUserAccountData(owner_).internalAccount);
        
        // uint32 twapDuration = 15;
        // uint ptPrice = sUSDeMarket.getPtToAssetRate(twapDuration);
        // ptPrice = tokenOut_ == address(USDC) ? ptPrice / 1e12 : ptPrice;

        // // 1 ozUSDC --- ptPrice
        // // amountIn --- x 

        // amountInPT = amountIn_.mulDivDown(ptPrice, 1e12);

        // // console.log('--- in redeem() ---');
        // // console.log('amountIn - ozUSDC: ', amountIn_);
        // // console.log('ptPrice: ', ptPrice);
        // // console.log('getPtToSyRate: ', sUSDeMarket.getPtToSyRate(twapDuration));
        // // console.log('amountInPT: ', amountInPT);
        // // console.log('pt bal - intAcc: ', sUSDe_PT_26SEP.balanceOf(address(account)));

        // uint ozUSDCtoPTrate = OZ.getExchangeRate();
        // console.log('ozUSDCtoPTrate: ', ozUSDCtoPTrate);


        // 1 ozUSDC --- ozUSDCtoPTrate
        // amountIn_ ---- x

        // amountIn_.mulDivDown(OZ.getExchangeRate());


        account.sellPT(amountIn_, address(account), tokenOut_);

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


    function totalAssets() public view override returns (uint256) {
        return _totalAssets;
    }

    // function _getBalancePT(address owner_) public view returns(uint) {
    //     address intAcc = OZ.getUserAccountData(owner_).internalAccount;
    //     return 
    // }

}