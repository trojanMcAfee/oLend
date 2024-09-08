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
import {AaveConfig, ERC20s, PendleConfig} from "../../contracts/AppStorage.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ozUSD} from "../../contracts/ozUSD.sol";
import {IERC20} from "../../contracts/interfaces/IERC20.sol";

import "forge-std/console.sol";


contract Setup is StateVars {

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('ethereum'), currentBlock); //blockOwnerPT + 100

        deal(address(sUSDe), address(this), 1_000 * 1e18);
        sUSDe.approve(address(pendleRouter), type(uint).max);
        YT.approve(address(pendleRouter), type(uint).max);

        payable(owner).transfer(100 * 1 ether);

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

        //Deploys ozUSD
        ozUSDimpl = new ozUSD();
        bytes memory data = abi.encodeWithSelector(ozUSDimpl.initialize.selector, 'Ozel Dollar', 'ozUSD');
        ozUSDproxy = new ERC1967Proxy(address(ozUSDimpl), data);
        ozUsd = IERC20(address(ozUSDproxy));

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

        //Deploy initial diamond cut
        AaveConfig memory aave = AaveConfig(aaveGW, aavePoolProvider);
        ERC20s memory tokens = ERC20s(aWETHaddr, USDCaddr, address(sUSDe), USDTaddr, address(ozUSDproxy));
        PendleConfig memory pendle = PendleConfig(address(pendleRouter), address(sUSDeMarket));

        bytes memory initData = abi.encodeWithSelector(
            initDiamond.init.selector, 
            aave,
            tokens,
            pendle
        );
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
        } else if (id_ == 2) { //2 - ozMinter
            length = 4;
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
            selectors[0] = minter.lend.selector;
            selectors[1] = minter.borrow.selector;
            selectors[2] = minter.redeem.selector;
            selectors[3] = minter.rebuyPT.selector;
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
        vm.label(aWETHaddr, 'aWETH');
        vm.label(address(aavePool), 'aavePool');
        vm.label(USDCaddr, 'USDCproxy');
        vm.label(0x43506849D7C04F9138D1A2050bbF3A0c054402dd, 'USDCimpl');
        vm.label(0xbFA3aAD535e1b996396698f89FFeC7ada0df17E8, 'ActionSwapPTV3_pendle');
        vm.label(0x4139cDC6345aFFbaC0692b43bed4D059Df3e6d65, 'sUSDe_SY');
        vm.label(0x1A6fCc85557BC4fB7B534ed835a03EF056552D52, 'marketFactory_pendle');
        vm.label(address(sUSDe_PT_26SEP), 'sUSDe_PT_26SEP');
    }



}