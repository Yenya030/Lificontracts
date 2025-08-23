// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {StargateFacetV2} from "lifi/Facets/StargateFacetV2.sol";

contract StargateFacetV2ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroTokenMessaging() public {
        StargateFacetV2 facet = new StargateFacetV2(address(0));
        assertEq(address(facet.tokenMessaging()), address(0));
    }
}

