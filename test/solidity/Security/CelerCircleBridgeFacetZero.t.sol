// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {CelerCircleBridgeFacet} from "lifi/Facets/CelerCircleBridgeFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {ICircleBridgeProxy} from "lifi/Interfaces/ICircleBridgeProxy.sol";
import {InvalidAmount} from "lifi/Errors/GenericErrors.sol";

contract CelerCircleBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        CelerCircleBridgeFacet facet = new CelerCircleBridgeFacet(
            ICircleBridgeProxy(address(0)),
            address(0)
        );

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "CelerCircleBridge",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        vm.expectRevert(InvalidAmount.selector);
        facet.startBridgeTokensViaCelerCircleBridge(bridgeData);
    }
}

