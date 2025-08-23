// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {OmniBridgeFacet} from "lifi/Facets/OmniBridgeFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {IOmniBridge} from "lifi/Interfaces/IOmniBridge.sol";

contract OmniBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        OmniBridgeFacet facet = new OmniBridgeFacet(IOmniBridge(address(0)), IOmniBridge(address(0)));

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
        facet.startBridgeTokensViaOmniBridge{value: 1}(data);
    }
}
