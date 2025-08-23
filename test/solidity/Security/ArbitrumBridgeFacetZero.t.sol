// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ArbitrumBridgeFacet} from "lifi/Facets/ArbitrumBridgeFacet.sol";
import {IGatewayRouter} from "lifi/Interfaces/IGatewayRouter.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract ArbitrumBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        ArbitrumBridgeFacet facet = new ArbitrumBridgeFacet(
            IGatewayRouter(address(0)),
            IGatewayRouter(address(0))
        );

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32(0),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(0),
            minAmount: 1,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        ArbitrumBridgeFacet.ArbitrumData memory arbData = ArbitrumBridgeFacet.ArbitrumData({
            maxSubmissionCost: 0,
            maxGas: 0,
            maxGasPrice: 0
        });

        vm.expectRevert();
        facet.startBridgeTokensViaArbitrumBridge(bridgeData, arbData);
        // use facet to silence warnings
        assertEq(address(facet) != address(0), true);
    }
}

