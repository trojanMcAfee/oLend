// SPDX-License-Identifier: UNLICENSED
// pragma solidity 0.8.26;
pragma solidity >=0.8.23 <0.9.0;


import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {Storage} from "../../contracts/Storage.sol";
import {IPAllActionV3} from "@pendle/core-v2/contracts/interfaces/IPAllActionV3.sol";
import {IPMarket} from "@pendle/core-v2/contracts/interfaces/IPMarket.sol";
import {IStandardizedYield} from "@pendle/core-v2/contracts/interfaces/IStandardizedYield.sol";
import {IPPrincipalToken} from "@pendle/core-v2/contracts/interfaces/IPPrincipalToken.sol";
// import {IERC20} from "../../lib/forge-std/src/interfaces/IERC20.sol";


contract RouterTest is Test, Storage {

    IPAllActionV3 pendleRouter;
    IPMarket sUSDeMarket;
    

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('ethereum'), 20665666);

        pendleRouter = IPAllActionV3(router);
        sUSDeMarket = IPMarket(pendleMarket);

        deal(address(sUSDe), address(this), 1_000 * 1e18);
        sUSDe.approve(address(pendleRouter), type(uint).max);
    }

    
    function test_router() public {
        (IStandardizedYield SY, IPPrincipalToken PT,) = sUSDeMarket.readTokens();

        console.log('SY: ', address(SY));
        console.log('PT: ', address(PT));

        
    }
}
