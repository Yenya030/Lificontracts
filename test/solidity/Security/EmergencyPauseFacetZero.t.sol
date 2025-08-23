// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {EmergencyPauseFacet} from "lifi/Facets/EmergencyPauseFacet.sol";

contract EmergencyPauseFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroPauser() public {
        EmergencyPauseFacet facet = new EmergencyPauseFacet(address(0));
        assertEq(facet.pauserWallet(), address(0));
    }
}
