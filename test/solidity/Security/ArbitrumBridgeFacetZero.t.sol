// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ArbitrumBridgeFacet} from "lifi/Facets/ArbitrumBridgeFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {IGatewayRouter} from "lifi/Interfaces/IGatewayRouter.sol";

contract ArbitrumBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        ArbitrumBridgeFacet facet = new ArbitrumBridgeFacet(
            IGatewayRouter(address(0)),
            IGatewayRouter(address(0))
        );

        ILiFi.BridgeData memory data = ILiFi.BridgeData({
            transactionId: bytes32(""),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: 42161,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        ArbitrumBridgeFacet.ArbitrumData memory arb =
            ArbitrumBridgeFacet.ArbitrumData({
                maxSubmissionCost: 0,
                maxGas: 0,
                maxGasPrice: 0
            });

        vm.expectRevert();
        facet.startBridgeTokensViaArbitrumBridge{value: 1}(data, arb);
    }
}

