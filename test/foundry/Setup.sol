// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StateVars} from "../../contracts/StateVars.sol";

import {DiamondCutFacet} from "../../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../contracts/facets/OwnershipFacet.sol";
import {Diamond} from "../Diamond.sol";


contract Setup is StateVars, Test {

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('ethereum'), blockOwnerPT); //blockOwnerPT + 100

        deal(address(sUSDe), address(this), 1_000 * 1e18);
        sUSDe.approve(address(pendleRouter), type(uint).max);
        YT.approve(address(pendleRouter), type(uint).max);

        _runDiamondSetup();

        _setLabels();
    }



    //********* */

    function _runDiamondSetup() private {
        cut = new DiamondCutFacet();
        loupe = new DiamondLoupeFacet();
        owner = new OwnershipFacet();

        OZ = new Diamond();

    }

    function _setLabels() private {
        vm.label(address(pendleRouter), 'pendleRouter');
        vm.label(address(sUSDeMarket), 'sUSDeMarket');
        vm.label(address(sUSDe), 'sUSDe');
        vm.label(ownerPT, 'ownerPT');
    }



}