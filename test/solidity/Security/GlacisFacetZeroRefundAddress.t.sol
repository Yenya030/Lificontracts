// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import { Test } from "forge-std/Test.sol";
import { GlacisFacet } from "lifi/Facets/GlacisFacet.sol";
import { IGlacisAirlift } from "lifi/Interfaces/IGlacisAirlift.sol";
import { ILiFi } from "lifi/Interfaces/ILiFi.sol";

contract GlacisFacetHarness is GlacisFacet {
    constructor(IGlacisAirlift airlift) GlacisFacet(airlift) {}
    function exposed_startBridge(
        ILiFi.BridgeData memory bridgeData,
        GlacisData calldata glacisData
    ) external {
        _startBridge(bridgeData, glacisData);
    }
}

contract GlacisFacetZeroRefundAddressTest is Test {
    GlacisFacetHarness facet;

    function setUp() public {
        facet = new GlacisFacetHarness(IGlacisAirlift(address(1)));
    }

    function test_StartBridge_RevertsOnZeroRefundAddress() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32(0),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(this),
            minAmount: 1,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        GlacisFacet.GlacisData memory glacisData = GlacisFacet.GlacisData({
            refundAddress: address(0),
            nativeFee: 0
        });

        vm.expectRevert(GlacisFacet.InvalidRefundAddress.selector);
        facet.exposed_startBridge(bridgeData, glacisData);
    }
}

