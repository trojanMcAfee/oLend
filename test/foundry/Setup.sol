// SPDX-License-Identifier: UNLICENSED
pragma solidity 0.8.26;


// import {Test, console} from "../../lib/forge-std/src/Test.sol";
import {StateVars} from "../../contracts/StateVars.sol";

import {DiamondCutFacet} from "../../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../contracts/facets/OwnershipFacet.sol";
import {ozMinter} from "../../contracts/facets/ozMinter.sol";
import {DiamondInit} from "../../contracts/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../../contracts/interfaces/IDiamondCut.sol";
import {ozIDiamond} from "../../contracts/interfaces/ozIDiamond.sol";
import {Diamond} from "../../contracts/Diamond.sol";


contract Setup is StateVars {

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
        //Deploy facets and init diamond config
        cut = new DiamondCutFacet();
        loupe = new DiamondLoupeFacet();
        ownership = new OwnershipFacet();
        minter = new ozMinter();

        ozDiamond = new Diamond(owner, address(cut));
        OZ = ozIDiamond(address(ozDiamond));
        initDiamond = new DiamondInit();

        //Create initial FacetCuts
        address[3] memory facets = [
            address(loupe),
            address(ownership),
            address(minter)
        ];

        uint length = facets.length;
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](length);

        for (uint i=0; i < length; i++) {
            cuts[i] = _createCut(facets[i], i);     
        }

        // IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](3);
        // cuts[0] = _createCut(address(loupe), 0);
        // cuts[1] = _createCut(address(ownership), 1);
        // cuts[2] = _createCut(address(minter), 2);

        //Deploy initial diamond cut
        bytes memory initData = abi.encodeWithSelector(initDiamond.init.selector);
        vm.prank(owner);
        OZ.diamondCut(cuts, address(initDiamond), initData);
    }


    function _createCut(
        address contractAddr_, 
        uint id_
    ) private view returns(IDiamondCut.FacetCut memory cut) {
        uint length;
        if (id_ == 0) {
            length = 5;
        } else if (id_ == 1) {
            length = 2;
        } else if (id_ == 2) {
            length = 1;
        }

        bytes4[] memory selectors = new bytes4[](length);

        if (id_ == 0) {
            selectors[0] = loupe.facets.selector;
            selectors[1] = loupe.facetFunctionSelectors.selector;
            selectors[2] = loupe.facetAddresses.selector;
            selectors[3] = loupe.facetAddress.selector;
            selectors[4] = loupe.supportsInterface.selector;
        } else if (id_ == 1) {
            selectors[0] = ownership.transferOwnership.selector;
            selectors[1] = ownership.owner.selector;
        } else if (id_ == 2) {
            selectors[0] = minter.sayHello.selector;
        }
       

        cut = IDiamondCut.FacetCut({
            facetAddress: contractAddr_,
            action: IDiamondCut.FacetCutAction.Add,
            functionSelectors: selectors
        });
    }


    function _setLabels() private {
        vm.label(address(pendleRouter), 'pendleRouter');
        vm.label(address(sUSDeMarket), 'sUSDeMarket');
        vm.label(address(sUSDe), 'sUSDe');
        vm.label(ownerPT, 'ownerPT');
        vm.label(address(sUSDe), 'sUSDe');
        vm.label(address(YT), 'sUSDe_YT_26SEP');
    }



}