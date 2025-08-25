// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {PeripheryRegistryFacet} from "lifi/Facets/PeripheryRegistryFacet.sol";

contract PeripheryRegistryFacetZeroAddressTest is Test {
    PeripheryRegistryFacet facet;

    function setUp() public {
        facet = new PeripheryRegistryFacet();
    }

    function test_registerAllowsZeroAddress() public {
        vm.prank(address(0));
        facet.registerPeripheryContract("test", address(0));
        assertEq(facet.getPeripheryContract("test"), address(0));
    }
}

