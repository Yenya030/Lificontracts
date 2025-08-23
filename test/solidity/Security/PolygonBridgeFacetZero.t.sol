// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {PolygonBridgeFacet} from "lifi/Facets/PolygonBridgeFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {IRootChainManager} from "lifi/Interfaces/IRootChainManager.sol";

contract PolygonBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        PolygonBridgeFacet facet =
            new PolygonBridgeFacet(IRootChainManager(address(0)), address(0));

        ILiFi.BridgeData memory data = ILiFi.BridgeData({
            transactionId: bytes32(""),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: 137,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        vm.expectRevert();
        facet.startBridgeTokensViaPolygonBridge{value: 1}(data);
    }
}

