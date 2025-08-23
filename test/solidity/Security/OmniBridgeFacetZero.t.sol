// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {OmniBridgeFacet} from "lifi/Facets/OmniBridgeFacet.sol";
import {IOmniBridge} from "lifi/Interfaces/IOmniBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract OmniBridgeFacetZeroAddressTest is Test {
    OmniBridgeFacet internal facet;

    function setUp() public {
        facet = new OmniBridgeFacet(
            IOmniBridge(address(0)),
            IOmniBridge(address(0))
        );
    }

    function test_ConstructorAllowsZeroAddresses() public {
        // deployment in setUp would revert if constructor rejected zero addresses
        assertTrue(address(facet) != address(0));
    }

    function test_startBridgeTokensViaOmniBridgeRevertsWithZeroAddresses() public {
        vm.deal(address(this), 1);
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32(0),
            bridge: "omni",
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
        facet.startBridgeTokensViaOmniBridge{value: 1}(bridgeData);
    }
}

