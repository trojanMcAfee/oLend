// SPDX-License-Identifier: UNLICENSED
pragma solidity >=0.8.23 <0.9.0;


import {IStandardizedYield} from "@pendle/core-v2/contracts/interfaces/IStandardizedYield.sol";
import {IPPrincipalToken} from "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";
import {Setup} from "./Setup.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {stdStorage, StdStorage} from "forge-std/Test.sol";              

import {console} from "../../lib/forge-std/src/Test.sol";



contract RouterTest is Setup { 

    using stdStorage for StdStorage;
   
    
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
        require(sUSDeBalance > 0, 'sUSDeBalance less than 0');
        console.log('sUSDeBalance pre everything: ', sUSDeBalance);

        (uint256 netPyOut,) =
            pendleRouter.mintPyFromToken(address(this), address(YT), 0, createTokenInputStruct(address(sUSDe), sUSDeBalance));

        uint exactYtIn = YT.balanceOf(address(this));
        console.log('');
        console.log('netPyOut - post mint: ', netPyOut);
        console.log('YT - post mint: ', exactYtIn);
        
        uint balancePT = sUSDe_PT_26SEP.balanceOf(address(this));
        console.log('sUSDe_PT_26SEP bal: ', balancePT);

        console.log('');

        //Swap YT for PT
        // pendleRouter.swapExactYtForPt(address(this), address(sUSDeMarket), exactYtIn, 0, defaultApprox);
        // console.log('PT bal - post swap: ', sUSDe_PT_26SEP.balanceOf(address(this)));
        // console.log('YT bal - post swap: ', YT.balanceOf(address(this)));

        //Swap PT for token
        console.log('sUSDe bal - pre swap: ', sUSDe.balanceOf(address(this)));
        sUSDe_PT_26SEP.approve(address(pendleRouter), type(uint).max);

        (uint256 netTokenOut,,) = pendleRouter.swapExactPtForToken(
            address(this), address(sUSDeMarket), balancePT, createTokenOutputStruct(address(sUSDe), 0), emptyLimit
        );

        console.log('netTokenOut: ', netTokenOut);   
        console.log('sUSDe bal - post swap: ', sUSDe.balanceOf(address(this)));
    }




    function test_diamond() public {
        uint ethToSend = owner.balance;
        require(ethToSend == 100 * 1 ether, 'owner not enough balance');

        IERC20 aWETH = IERC20(aWETHaddr);
        uint aWETH_bal = aWETH.balanceOf(address(OZ));
        console.log('aWETH_bal pre lend: ', aWETH_bal);

        vm.prank(owner);
        OZ.lend{value: 1 ether}(true);

        aWETH_bal = aWETH.balanceOf(address(OZ));
        console.log('aWETH_bal post lend: ', aWETH_bal);
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
        console.log('aUSDC bal - pre borrow - 0: ', IERC20(USDCaddr).balanceOf(address(OZ)));

        uint toBorrow = (availableBorrowsBase / 1e2) - (1 * 1e6);
        OZ.borrow(toBorrow);

        console.log('aUSDC bal - post borrow - not 0: ', IERC20(USDCaddr).balanceOf(address(OZ)));

    }


    function test_swap() public {
        OZ.do_swap();
    }



    
    
}
