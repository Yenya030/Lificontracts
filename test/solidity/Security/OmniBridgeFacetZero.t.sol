// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {OmniBridgeFacet} from "lifi/Facets/OmniBridgeFacet.sol";
import {IOmniBridge} from "lifi/Interfaces/IOmniBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract OmniBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        OmniBridgeFacet facet = new OmniBridgeFacet(IOmniBridge(address(0)), IOmniBridge(address(0)));

        vm.deal(address(this), 1 ether);

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "omniBridge",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: block.chainid + 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        uint256 balanceBefore = address(this).balance;
        vm.expectRevert();
        facet.startBridgeTokensViaOmniBridge{value: 1}(bridgeData);
        assertEq(address(this).balance, balanceBefore, "balance unchanged after revert");
    }
}
