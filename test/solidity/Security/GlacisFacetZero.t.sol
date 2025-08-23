// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GlacisFacet} from "lifi/Facets/GlacisFacet.sol";
import {IGlacisAirlift} from "lifi/Interfaces/IGlacisAirlift.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";
import {TestToken} from "../utils/TestToken.sol";

contract GlacisFacetZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroAirlift() public {
        vm.expectRevert(InvalidConfig.selector);
        new GlacisFacet(IGlacisAirlift(address(0)));
    }

    function test_StartBridgeTokensViaGlacisRevertsOnZeroRefundAddress() public {
        GlacisFacet facet = new GlacisFacet(IGlacisAirlift(address(0x1)));

        TestToken token = new TestToken("T", "T", 18);
        token.mint(address(this), 1 ether);
        token.approve(address(facet), type(uint256).max);

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "glacis",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(token),
            receiver: address(1),
            minAmount: 1 ether,
            destinationChainId: block.chainid + 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        GlacisFacet.GlacisData memory gData = GlacisFacet.GlacisData({
            refundAddress: address(0),
            nativeFee: 0
        });

        vm.expectRevert(GlacisFacet.InvalidRefundAddress.selector);
        facet.startBridgeTokensViaGlacis(bridgeData, gData);
    }
}

