// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {CBridgeFacetPacked} from "lifi/Facets/CBridgeFacetPacked.sol";
import {ICBridge} from "lifi/Interfaces/ICBridge.sol";

contract CBridgeFacetPackedZeroAddressTest is Test {
    function test_ConstructorAllowsZeroCBridgeAddress() public {
        CBridgeFacetPacked facet = new CBridgeFacetPacked(ICBridge(address(0)), address(this));

        vm.deal(address(this), 1 ether);

        CBridgeFacetPacked facetRef = facet; // to avoid stack too deep? not necessary

        vm.expectRevert();
        facetRef.startBridgeTokensViaCBridgeNativeMin{value: 1 ether}(
            bytes32("tx"),
            address(1),
            uint64(block.chainid + 1),
            0,
            0
        );
    }
}

