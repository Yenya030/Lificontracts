// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {OptimismBridgeFacet} from "lifi/Facets/OptimismBridgeFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {IL1StandardBridge} from "lifi/Interfaces/IL1StandardBridge.sol";
import {LibDiamond} from "lifi/Libraries/LibDiamond.sol";

contract TestOptimismFacet is OptimismBridgeFacet {
    function initOwner() external {
        LibDiamond.setContractOwner(msg.sender);
    }
}

contract OptimismBridgeFacetZeroStandardBridgeTest is Test {
    function test_InitAllowsZeroStandardBridge() public {
        TestOptimismFacet facet = new TestOptimismFacet();
        facet.initOwner();
        OptimismBridgeFacet.Config[] memory configs = new OptimismBridgeFacet.Config[](0);
        facet.initOptimism(configs, IL1StandardBridge(address(0)));

        ILiFi.BridgeData memory data = ILiFi.BridgeData({
            transactionId: bytes32(""),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: 10,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        OptimismBridgeFacet.OptimismData memory optimism = OptimismBridgeFacet.OptimismData({
            assetIdOnL2: address(0),
            l2Gas: 0,
            isSynthetix: false
        });

        vm.expectRevert();
        facet.startBridgeTokensViaOptimismBridge{value:1}(data, optimism);
    }
}

