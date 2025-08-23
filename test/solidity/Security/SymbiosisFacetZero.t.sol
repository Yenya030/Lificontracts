// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SymbiosisFacet} from "lifi/Facets/SymbiosisFacet.sol";
import {ISymbiosisMetaRouter} from "lifi/Interfaces/ISymbiosisMetaRouter.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract SymbiosisFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        SymbiosisFacet facet = new SymbiosisFacet(
            ISymbiosisMetaRouter(address(0)),
            address(0)
        );

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

        address[] memory approvedTokens = new address[](0);

        SymbiosisFacet.SymbiosisData memory symbiosisData = SymbiosisFacet.SymbiosisData({
            firstSwapCalldata: "",
            secondSwapCalldata: "",
            intermediateToken: address(0),
            firstDexRouter: address(0),
            secondDexRouter: address(0),
            approvedTokens: approvedTokens,
            callTo: address(0),
            callData: ""
        });

        vm.expectRevert();
        facet.startBridgeTokensViaSymbiosis{value: 1}(bridgeData, symbiosisData);
    }
}

