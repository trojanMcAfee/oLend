// SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;
pragma solidity >=0.8.23 <0.9.0;


import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StateVars} from "../../contracts/StateVars.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IStandardizedYield} from "@pendle/core-v2/contracts/interfaces/IStandardizedYield.sol";
import {IPPrincipalToken} from "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";
// import {IERC20} from "../../lib/forge-std/src/interfaces/IERC20.sol";


contract RouterTest is Test, StateVars {

    IPAllActionV3 pendleRouter;
    IPMarket sUSDeMarket;
    

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('ethereum'), 20665666);

        pendleRouter = IPAllActionV3(router);
        sUSDeMarket = IPMarket(pendleMarket);

        deal(address(sUSDe), address(this), 1_000 * 1e18);
        sUSDe.approve(address(pendleRouter), type(uint).max);

        _setLabels();
    }

    
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

        (uint256 netPtOut,,) = pendleRouter.swapExactTokenForPt(
            address(this), address(sUSDeMarket), 0, defaultApprox, createTokenInputStruct(address(sUSDe), sUSDeBalance), emptyLimit
        );
        console.log("netPtOut: ", netPtOut);
    }


    //********* */
    
    function _setLabels() private {
        vm.label(address(pendleRouter), 'pendleRouter');
        vm.label(address(sUSDeMarket), 'sUSDeMarket');
        vm.label(address(sUSDe), 'sUSDe');
    }
    
}
