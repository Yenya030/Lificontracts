// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {PolygonBridgeFacet} from "lifi/Facets/PolygonBridgeFacet.sol";
import {IRootChainManager} from "lifi/Interfaces/IRootChainManager.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract PolygonBridgeFacetZeroAddressTest is Test {
    PolygonBridgeFacet internal facet;

    function setUp() public {
        facet = new PolygonBridgeFacet(IRootChainManager(address(0)), address(0));
    }

    function test_ConstructorAllowsZeroAddresses() public {
        assertTrue(address(facet) != address(0));
    }

    function test_startBridgeTokensViaPolygonBridgeRevertsWithZeroAddresses() public {
        vm.deal(address(this), 1);
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32(0),
            bridge: "polygon", 
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(this),
            minAmount: 1,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        vm.expectRevert();
        facet.startBridgeTokensViaPolygonBridge{value: 1}(bridgeData);
    }
}

