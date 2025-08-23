// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GenericSwapFacetV3} from "lifi/Facets/GenericSwapFacetV3.sol";

contract GenericSwapFacetV3ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroNativeAddress() public {
        GenericSwapFacetV3 facet = new GenericSwapFacetV3(address(0));
        assertEq(facet.NATIVE_ADDRESS(), address(0));
    }
}

