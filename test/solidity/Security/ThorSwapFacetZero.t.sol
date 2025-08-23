// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ThorSwapFacet} from "lifi/Facets/ThorSwapFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract ThorSwapFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroRouter() public {
        ThorSwapFacet facet = new ThorSwapFacet(address(0));
        vm.deal(address(this), 1 ether);

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "thorswap",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: block.chainid + 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        ThorSwapFacet.ThorSwapData memory thorData = ThorSwapFacet.ThorSwapData({
            vault: address(2),
            memo: "",
            expiration: block.timestamp + 1
        });

        vm.expectRevert();
        facet.startBridgeTokensViaThorSwap{value: 1}(bridgeData, thorData);
    }
}

