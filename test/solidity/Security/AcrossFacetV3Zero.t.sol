// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {AcrossFacetV3} from "lifi/Facets/AcrossFacetV3.sol";
import {IAcrossSpokePool} from "lifi/Interfaces/IAcrossSpokePool.sol";

contract AcrossFacetV3ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        AcrossFacetV3 facet = new AcrossFacetV3(
            IAcrossSpokePool(address(0)),
            address(0)
        );
        assertEq(address(facet.spokePool()), address(0));
        assertEq(facet.wrappedNative(), address(0));
    }
}

