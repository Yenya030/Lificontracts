// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SquidFacet} from "lifi/Facets/SquidFacet.sol";
import {ISquidRouter} from "lifi/Interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "lifi/Interfaces/ISquidMulticall.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract SquidFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddressRouter() public {
        SquidFacet facet = new SquidFacet(ISquidRouter(address(0)));

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

        ISquidMulticall.Call[] memory calls;

        SquidFacet.SquidData memory squidData = SquidFacet.SquidData({
            routeType: SquidFacet.RouteType.BridgeCall,
            destinationChain: "",
            destinationAddress: "",
            bridgedTokenSymbol: "",
            depositAssetId: address(0),
            sourceCalls: calls,
            payload: "",
            fee: 0,
            enableExpress: false
        });

        vm.expectRevert();
        facet.startBridgeTokensViaSquid{value: 1}(bridgeData, squidData);
    }
}
