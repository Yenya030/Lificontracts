// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ThorSwapFacet} from "lifi/Facets/ThorSwapFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract ThorSwapFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroRouter() public {
        ThorSwapFacet facet = new ThorSwapFacet(address(0));

        ILiFi.BridgeData memory data = ILiFi.BridgeData({
            transactionId: bytes32(""),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        ThorSwapFacet.ThorSwapData memory tsData = ThorSwapFacet.ThorSwapData({
            vault: address(0),
            memo: "",
            expiration: block.timestamp
        });

        vm.expectRevert();
        facet.startBridgeTokensViaThorSwap{value: 1}(data, tsData);
    }
}

