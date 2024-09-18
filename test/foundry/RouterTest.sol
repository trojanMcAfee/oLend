// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;


import {IWrappedTokenGatewayV3} from "@aave/periphery-v3/contracts/misc/interfaces/IWrappedTokenGatewayV3.sol";
import {IStandardizedYield} from "@pendle/core-v2/contracts/interfaces/IStandardizedYield.sol";
import {IPPrincipalToken} from "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";
import {Setup} from "./Setup.sol";
// import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {IERC20} from "../../contracts/interfaces/IERC20.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";  
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";   
import {PendlePYOracleLib} from "@pendle/core-v2/contracts/oracles/PendlePYOracleLib.sol";   
import {ICreditDelegationToken} from "@aave/core-v3/contracts/interfaces/ICreditDelegationToken.sol";      
import {IPool, DataTypes} from "@aave/core-v3/contracts/interfaces/IPool.sol";

import {console} from "../../lib/forge-std/src/Test.sol";



contract RouterTest is Setup { 

    using stdStorage for StdStorage;
    using PendlePYOracleLib for *;
   
    
    function test_router() public {
        (IStandardizedYield SY, IPPrincipalToken PT,) = sUSDeMarket.readTokens();

        console.log('SY: ', address(SY));
        console.log('PT: ', address(PT));
        //---------

        uint sUSDeBalance = sUSDe.balanceOf(address(this));
        require(sUSDeBalance > 0, 'sUSDeBalance less than 0');

        console.log('expiry: ', sUSDeMarket.expiry());
        console.log('stamp: ', block.timestamp);

        console.log('sUSDeBalance: ', sUSDeBalance);

        // console.log('stamp: ', block.timestamp);
        (uint256 netPtOut,,) = pendleRouter.swapExactTokenForPt(
            address(this), 
            address(sUSDeMarket), 
            0, 
            defaultApprox, 
            createTokenInputStruct(address(sUSDe), sUSDeBalance), 
            emptyLimit
        );
        console.log("netPtOut: ", netPtOut);
    }


    function test_mintPT() public {
        //Mint PT and YT
        uint sUSDeBalance = sUSDe.balanceOf(address(this));
        require(sUSDeBalance > 0, 'customErr: sUSDeBalance less than 0');
        console.log('sUSDeBalance pre everything: ', sUSDeBalance);

        (uint256 netPyOut,) =
            pendleRouter.mintPyFromToken(address(this), address(YT), 0, createTokenInputStruct(address(sUSDe), sUSDeBalance));

        uint exactYtIn = YT.balanceOf(address(this));
        console.log('');
        console.log('netPyOut - post mint: ', netPyOut);
        console.log('YT - post mint: ', exactYtIn);
        console.log('');
        
        uint balancePT = sUSDe_PT_26SEP.balanceOf(address(this));
        console.log('sUSDe_PT_26SEP bal - pre YT > PT swap: ', balancePT);

        //Swap YT for PT
        pendleRouter.swapExactYtForPt(address(this), address(sUSDeMarket), exactYtIn, 0, defaultApprox);
        balancePT = sUSDe_PT_26SEP.balanceOf(address(this));
        console.log('PT bal - post YT > PT swap: ', balancePT);
        console.log('YT bal - post YT > PT swap - 0: ', YT.balanceOf(address(this)));

        uint apy = ((balancePT - sUSDeBalance) * (100 * 1e18)) / sUSDeBalance;
        console.log('APY: ', apy);


        // console.log('');

        // //Swap PT for token
        // console.log('sUSDe bal - pre swap: ', sUSDe.balanceOf(address(this)));
        // sUSDe_PT_26SEP.approve(address(pendleRouter), type(uint).max);

        // (uint256 netTokenOut,,) = pendleRouter.swapExactPtForToken(
        //     address(this), address(sUSDeMarket), balancePT, createTokenOutputStruct(address(sUSDe), 0), emptyLimit
        // );

        // console.log('netTokenOut: ', netTokenOut);   
        // console.log('sUSDe bal - post swap: ', sUSDe.balanceOf(address(this)));
    }


    function test_flow() public {
        uint ethToSend = owner.balance;
        require(ethToSend == 100 * 1 ether, 'owner not enough balance');

        //User LENDS 
        vm.prank(owner);
        uint amountIn = 1 ether;
        OZ.lend{value: 1 ether}(amountIn, true);

        (,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(address(OZ));
        uint toBorrow = (availableBorrowsBase / 1e2) - (1 * 1e6);
        console.log('amount to borrow in USD after lend() - aave: ', availableBorrowsBase);

        //User BORROWS
        vm.startPrank(owner);
        OZ.borrow(toBorrow, owner);
        vm.stopPrank();

        uint ptQuote = OZ.quotePT();

        //External user BUYS discounted PT
        vm.startPrank(second_owner);
        IERC20(USDCaddr).approve(address(OZ), type(uint).max);
        OZ.rebuyPT(ptQuote / 1e12);

        //External user MINTS ozUSD to user when buying discounted PT
        OZ.finishBorrow(owner);
        vm.stopPrank();

        uint balanceOzUSD = ozUsd.balanceOf(owner);
        console.log('balanceOzUSD - owner: ', balanceOzUSD);
        console.log('');
    }


    function test_diamond() public {
        uint ethToSend = owner.balance;
        require(ethToSend == 100 * 1 ether, 'owner not enough balance');

        IERC20 aWETH = IERC20(aWETHaddr);
        uint aWETH_bal = aWETH.balanceOf(address(OZ));
        console.log('aWETH_bal pre lend: ', aWETH_bal);

        vm.prank(owner);
        uint amountIn = 1 ether;
        OZ.lend{value: amountIn}(amountIn, true);

        aWETH_bal = aWETH.balanceOf(address(OZ));
        console.log('aWETH_bal post lend - 0: ', aWETH_bal);
        //------

        (
            uint256 totalCollateralBase,
            uint256 totalDebtBase,
            uint256 availableBorrowsBase,
            uint256 currentLiquidationThreshold,
            uint256 ltv,
            uint256 healthFactor
        ) = aavePool.getUserAccountData(address(OZ));

        // console.log('');
        // console.log('totalCollateralBase: ', totalCollateralBase);
        // console.log('totalDebtBase: ', totalDebtBase);
        // console.log('availableBorrowsBase: ', availableBorrowsBase);
        // console.log('currentLiquidationThreshold: ', currentLiquidationThreshold);
        // console.log('ltv: ', ltv);
        // console.log('healthFactor: ', healthFactor);

        console.log('');

        uint toBorrow = (availableBorrowsBase / 1e2) - (1 * 1e6);
        console.log('toBorrow - ozUSD: ', toBorrow);
        OZ.borrow(toBorrow, owner);

        uint ozUSDbal = ozUsd.balanceOf(owner);
        console.log('ozUSDbal - post borrow: ', ozUSDbal);
        console.log('');

        //---------------
        // vm.startPrank(address(OZ));
        // sUSDe_PT_26SEP.approve(address(pendleRouter), type(uint).max);
        // // uint ozUsdToRedeem = 1000 * 1e18; //PT
        // uint ozUsdToRedeem = sUSDe_PT_26SEP.balanceOf(address(OZ));
        // OZ.redeem(ozUsdToRedeem, owner);
        // vm.stopPrank();
        //-----------
        
        console.log('--- ozOracle ---');
        uint ptQuote = OZ.quotePT();
        console.log('ptQuote: ', ptQuote);
        
        console.log('--- end ---');
        console.log('');

        // uint balancePT = sUSDe_PT_26SEP.balanceOf(address(OZ));
        // uint discount = (500 * balancePT) / 10_000;
        // uint discountedPT = balancePT - discount;

        // console.log('discountedPT: ', discountedPT);
        // console.log('PT bal oz - in test - pre rebuy: ', balancePT);
        // console.log('PT bal - second owner - pre rebuy: ', sUSDe_PT_26SEP.balanceOf(second_owner));
        // console.log('USDC bal - second owner - pre buy: ', IERC20(USDCaddr).balanceOf(second_owner));
        // console.log('USDC bal - oz - pre buy: ', IERC20(USDCaddr).balanceOf(address(OZ)));
        // console.log('discountedPT / 1e12: ', discountedPT / 1e12);
        // console.log('');

        // vm.startPrank(second_owner);
        // IERC20(USDCaddr).approve(address(OZ), discountedPT);
        // OZ.rebuyPT(ptQuote / 1e12);

        // console.log('PT bal - second owner - post rebuy: ', sUSDe_PT_26SEP.balanceOf(second_owner));
        // console.log('PT bal oz - in test - post rebuy: ', sUSDe_PT_26SEP.balanceOf(address(OZ)));
        // console.log('USDC bal - second owner - post rebuy: ', IERC20(USDCaddr).balanceOf(second_owner));
        // console.log('USDC bal - oz - post rebuy: ', IERC20(USDCaddr).balanceOf(address(OZ)));
    }


    function test_twap() public view {
        address routerStatic = 0x263833d47eA3fA4a30f269323aba6a107f9eB14C;
        address pendleOracle = 0x9a9Fa8338dd5E5B2188006f1Cd2Ef26d921650C2;
        uint32 duration = 15;
        
        // uint ptToAssetRate = MyWap(pendleOracle).getPtToAssetRate(sUSDeMarket, duration);
        uint ptToSyRate = sUSDeMarket.getPtToSyRate(duration);
        uint ptToAssetRate = sUSDeMarket.getPtToAssetRate(duration);
        console.log('ptToSyRate: ', ptToSyRate);
        console.log('ptToAssetRate: ', ptToAssetRate);

    }


    function test_liquidity() public {
        IERC20 SY = IERC20(0x4139cDC6345aFFbaC0692b43bed4D059Df3e6d65);
        IERC20 sUSDe_YT_26SEP = IERC20(0xdc02b77a3986da62C7A78FED73949C9767850809);
        IERC20 sUSDe_market = IERC20(0xd1D7D99764f8a52Aff007b7831cc02748b2013b5);
        
        // bytes32 transaction = 0x467c0c15148778d0b99a1d9f3bd7406fd0c58d8a6e3284a57a50e55ae0160165;
        // vm.rollFork(19909022 + 752); //752 fails - 753 succeeds 
        deal(address(sUSDe), address(this), 1_000 * 1e18);
        sUSDe.approve(address(pendleRouter), type(uint).max);
        YT.approve(address(pendleRouter), type(uint).max);

        uint balanceUSDe = USDe.balanceOf(address(sUSDe_PT_26SEP));
        uint balance_sUSDe = sUSDe.balanceOf(address(sUSDe_PT_26SEP));
        uint balancePT = sUSDe_PT_26SEP.balanceOf(address(sUSDe_PT_26SEP));
        uint balanceSY = SY.balanceOf(address(sUSDe_PT_26SEP));
        uint balanceYT = sUSDe_YT_26SEP.balanceOf(address(sUSDe_PT_26SEP));
        uint balanceMarket = sUSDe_market.balanceOf(address(sUSDe_PT_26SEP));

        console.log('--- PT ---');
        console.log('balance_PT_USDe: ', balanceUSDe);
        console.log('balance_PT_sUSDe: ', balance_sUSDe);
        console.log('balance_PT_PT: ', balancePT);
        console.log('balance_PT_SY: ', balanceSY);
        console.log('balance_PT_YT: ', balanceYT);
        console.log('balance_PT_market: ', balanceMarket);
        console.log('');

        //-------
        balanceUSDe = USDe.balanceOf(address(sUSDe_YT_26SEP));
        balance_sUSDe = sUSDe.balanceOf(address(sUSDe_YT_26SEP));
        balancePT = sUSDe_PT_26SEP.balanceOf(address(sUSDe_YT_26SEP));
        balanceSY = SY.balanceOf(address(sUSDe_YT_26SEP));
        balanceYT = sUSDe_YT_26SEP.balanceOf(address(sUSDe_YT_26SEP));
        balanceMarket = sUSDe_market.balanceOf(address(sUSDe_YT_26SEP));

        console.log('--- YT ---');
        console.log('balance_YT_USDe: ', balanceUSDe);
        console.log('balance_YT_sUSDe: ', balance_sUSDe);
        console.log('balance_YT_PT: ', balancePT);
        console.log('balance_YT_SY: ', balanceSY);
        console.log('balance_YT_YT: ', balanceYT);
        console.log('balance_YT_market: ', balanceMarket);
        console.log('');

        //--------
        balanceUSDe = USDe.balanceOf(address(sUSDe_market));
        balance_sUSDe = sUSDe.balanceOf(address(sUSDe_market));
        balancePT = sUSDe_PT_26SEP.balanceOf(address(sUSDe_market));
        balanceSY = SY.balanceOf(address(sUSDe_market));
        balanceYT = sUSDe_YT_26SEP.balanceOf(address(sUSDe_market));
        balanceMarket = sUSDe_market.balanceOf(address(sUSDe_market));

        console.log('--- Market ---');
        console.log('balance_market_USDe: ', balanceUSDe);
        console.log('balance_market_sUSDe: ', balance_sUSDe);
        console.log('balance_market_PT: ', balancePT);
        console.log('balance_market_SY: ', balanceSY);
        console.log('balance_market_YT: ', balanceYT);
        console.log('balance_market_market: ', balanceMarket);
        console.log('');

        test_mintPT();
    }


    function test_delegation() public {
        vm.prank(owner);
        IWrappedTokenGatewayV3(aaveGW).depositETH{value: 1 ether}(address(aavePool), owner, 0);

        (,,uint256 availableBorrowsBase,,,) = aavePool.getUserAccountData(owner);
        console.log('availableBorrowsBase owner - pre delegation: ', availableBorrowsBase);
        uint amountBorrow = (availableBorrowsBase / 1e2) - (1 * 1e6);

        (,,uint256 availableBorrowsBase4,,,) = aavePool.getUserAccountData(second_owner);
        console.log('availableBorrowsBase second_owner - pre delegation: ', availableBorrowsBase4);

        ICreditDelegationToken aaveVariableDebtUSDC = ICreditDelegationToken(0x72E95b8931767C79bA4EeE721354d6E99a61D004);
        vm.prank(owner);
        aaveVariableDebtUSDC.approveDelegation(second_owner, type(uint).max);

        console.log('');

        (,,uint256 availableBorrowsBase2,,,) = aavePool.getUserAccountData(owner);
        console.log('availableBorrowsBase owner - post delegation: ', availableBorrowsBase2);

        (,,uint256 availableBorrowsBase3,,,) = aavePool.getUserAccountData(second_owner);
        console.log('availableBorrowsBase second_owner - post delegation: ', availableBorrowsBase3);
        //-------------------

        console.log('');
        console.log('usdc bal second_owner - pre borrow: ', IERC20(USDCaddr).balanceOf(second_owner));
        
        vm.prank(second_owner);
        aavePool.borrow(USDCaddr, amountBorrow, 2, 0, owner);

        console.log('usdc bal second_owner - post borrow: ', IERC20(USDCaddr).balanceOf(second_owner));

    }


    function test_x() public view {
        DataTypes.ReserveData memory data = aavePool.getReserveData(USDCaddr);
        console.log('variableBorrowIndex: ', uint(data.variableBorrowIndex));

    }


    
    
}
