// SPDX-License-Identifier: GPL-2.0-or-later
pragma solidity 0.8.26;


// import {Test, console} from "../../lib/forge-std/src/Test.sol";
// import {StateVars} from "../../contracts/StateVars.sol";

import {DiamondCutFacet} from "../../contracts/facets/DiamondCutFacet.sol";
import {DiamondLoupeFacet} from "../../contracts/facets/DiamondLoupeFacet.sol";
import {OwnershipFacet} from "../../contracts/facets/OwnershipFacet.sol";
import {ozMinter} from "../../contracts/facets/ozMinter.sol";
import {DiamondInit} from "../../contracts/upgradeInitializers/DiamondInit.sol";
import {IDiamondCut} from "../../contracts/interfaces/IDiamondCut.sol";
import {ozIDiamond} from "../../contracts/interfaces/ozIDiamond.sol";
import {Diamond} from "../../contracts/Diamond.sol";
import {AaveConfig, ERC20s, PendleConfig, SysConfig, BalancerConfig, CurveConfig} from "../../contracts/AppStorage.sol";
import {ERC1967Proxy} from "@openzeppelin/contracts/proxy/ERC1967/ERC1967Proxy.sol";
import {ozUSDtoken} from "../../contracts/ozUSDtoken.sol";
import {ozRelayer} from "../../contracts/ozRelayer.sol";
import {IERC20} from "../../contracts/interfaces/IERC20.sol";
import {ozOracle} from "../../contracts/facets/ozOracle.sol";
import {ozIUSD} from "../../contracts/interfaces/ozIUSD.sol";
import {AppStorageTest} from "./AppStorageTest.sol";

import "forge-std/console.sol";


contract Setup is AppStorageTest {

    function setUp() public {
        vm.createSelectFork(vm.rpcUrl('ethereum'), currentBlock); //blockOwnerPT + 100 / currentBlock

        deal(address(sUSDe), address(this), 1_000 * 1e18);
        sUSDe.approve(address(pendleRouter), type(uint).max);

        YT.approve(address(pendleRouter), type(uint).max);
        deal(USDCaddr, second_owner, 10_000 * 1e6);

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
        oracle = new ozOracle();

        //Deploys ozUSDtoken
        ozUSDimpl = new ozUSDtoken(address(OZ));
        bytes memory data = abi.encodeWithSelector(
            ozUSDimpl.initialize.selector, 
            'Ozel Dollar', 
            'ozUSD'        
        );
        ozUSDproxy = new ERC1967Proxy(address(ozUSDimpl), data);
        ozUSD = ozIUSD(address(ozUSDproxy));

        //Deploys sys config
        relayer = new ozRelayer();

        //Create initial FacetCuts
        address[4] memory facets = [
            address(loupe),
            address(ownership),
            address(minter),
            address(oracle)
        ];

        uint length = facets.length;
        IDiamondCut.FacetCut[] memory cuts = new IDiamondCut.FacetCut[](length);

        for (uint i=0; i < length; i++) {
            cuts[i] = _createCut(facets[i], i);     
        }

        //Deploy initial diamond cut
        AaveConfig memory aave = AaveConfig(aaveGW, aavePoolProvider);

        BalancerConfig memory balancer = BalancerConfig(
            address(balancerPool_wstETHsUSDe),
            address(balancerVault),
            address(balancerPool_wstETHWETH)
        );

        ERC20s memory tokens = ERC20s(
            aWETHaddr, 
            USDCaddr, 
            address(sUSDe), 
            USDTaddr, 
            address(ozUSDproxy), 
            address(sUSDe_PT_26SEP),
            address(aaveVariableDebtUSDC),
            address(USDe),
            address(wstETH),
            address(WETH),
            address(sDAI),
            address(FRAX),
            address(WBTC)
        );

        PendleConfig memory pendle = PendleConfig(
            address(pendleRouter), 
            address(sUSDeMarket),
            twapDuration,
            ptDiscount
        );

        CurveConfig memory curve = CurveConfig(
            address(curveRouter), 
            address(curveAddressProvider),
            address(curvePool_sUSDesDAI),
            address(curvePool_sDAIFRAX),
            address(curvePool_FRAXUSDC),
            address(curvePool_USDCETHWBTC)
        );

        SysConfig memory sys = SysConfig(address(OZ), address(relayer), ETH);

        bytes memory initData = abi.encodeWithSelector(
            initDiamond.init.selector, 
            aave,
            balancer,
            pendle,
            curve,
            tokens,
            sys
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
        } else if (id_ == 2) { // ozMinter
            length = 6;
        } else if (id_ == 3) { // ozOracle
            length = 3;
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
            selectors[2] = minter.performRedemption.selector;
            selectors[3] = minter.rebuyPT.selector;
            selectors[4] = minter.finishBorrow.selector;
            selectors[5] = minter.getUserAccountData.selector;
        } else if (id_ == 3) {
            selectors[0] = oracle.quotePT.selector;
            selectors[1] = oracle.getVariableBorrowAPY.selector;
            selectors[2] = oracle.getVariableSupplyAPY.selector;
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
        vm.label(0x8903dBFFcA66b3Fbc027aC81912ea64Fa61A5219, 'ActionSwapYTV3_pendle');
        vm.label(0x41717de714Db8630F02Dea8f6A39C73A5b5C7df1, 'BorrowLogic_aave');
        vm.label(0x34339f94350EC5274ea44d0C37DAe9e968c44081, 'PoolInstance_aave');
        vm.label(aavePoolProvider, 'aavePoolProvider');
        vm.label(address(relayer), 'ozRelayer');
        vm.label(0xE592427A0AEce92De3Edee1F18E0157C05861564, 'swapRouter_uni');
        vm.label(0x7858E59e0C01EA06Df3aF3D20aC7B0003275D4Bf, 'USDC-USDT_uni');
        vm.label(0x98EE851a00abeE0d95D08cF4CA2BdCE32aeaAF7F ,'CurveTwocryptoFactory');
        vm.label(0x6A8cbed756804B16E05E741eDaBd5cB544AE21bf, 'CurveStableswapFactoryNG');
        vm.label(0xe06EBA9ceA16cc71d4498CdBA7240BB20d475890, 'CurveStableswapFactoryNGHandler');
        vm.label(address(curveRouter), 'curveRouter');
        vm.label(address(curveAddressProvider), 'curveAddressProvider');
        vm.label(address(curvePool_sUSDesDAI), 'curvePool_sUSDesDAI');
        vm.label(address(curvePool_sDAIFRAX), 'curvePool_sDAIFRAX');
        vm.label(address(curvePool_FRAXUSDC), 'curvePool_FRAXUSDC');
        vm.label(address(curvePool_USDCETHWBTC), 'curvePool_USDCETHWBTC');
        vm.label(0x33C5252f240f02123090cfF1D8E3B80FceC31e54, 'UnverifiedCrvContract');
        vm.label(address(USDe), 'USDe');
        vm.label(address(sDAI), 'sDAI');
        vm.label(address(FRAX), 'FRAX');
    }



}