// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {HopFacetPacked} from "lifi/Facets/HopFacetPacked.sol";

contract HopFacetPackedZeroTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        HopFacetPacked facet = new HopFacetPacked(address(0), address(0));
        assertEq(facet.owner(), address(0));
        assertEq(facet.nativeBridge(), address(0));
    }
}

