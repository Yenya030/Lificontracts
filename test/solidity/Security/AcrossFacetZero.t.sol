// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {AcrossFacet} from "lifi/Facets/AcrossFacet.sol";
import {IAcrossSpokePool} from "lifi/Interfaces/IAcrossSpokePool.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract AcrossFacetZeroAddressTest is Test {
    AcrossFacet facet;

    function setUp() public {
        facet = new AcrossFacet(IAcrossSpokePool(address(0)), address(0));
    }

    function test_ConstructorAllowsZeroAddresses() public {
        // deployment succeeded with zero addresses
        assertTrue(address(facet) != address(0));
    }

    function test_StartBridgeRevertsWithZeroConfig() public {
        ILiFi.BridgeData memory data = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "Across",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(0x1),
            minAmount: 1 ether,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });
        AcrossFacet.AcrossData memory acrossData =
            AcrossFacet.AcrossData({relayerFeePct: 0, quoteTimestamp: 0, message: "", maxCount: 0});
        vm.expectRevert();
        facet.startBridgeTokensViaAcross{value: 1 ether}(data, acrossData);
    }
}
