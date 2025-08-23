// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {AcrossFacetPackedV3} from "lifi/Facets/AcrossFacetPackedV3.sol";
import {IAcrossSpokePool} from "lifi/Interfaces/IAcrossSpokePool.sol";

contract AcrossFacetPackedV3ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        AcrossFacetPackedV3 facet = new AcrossFacetPackedV3(
            IAcrossSpokePool(address(0)),
            address(0),
            address(this)
        );
        assertEq(address(facet.spokePool()), address(0));
        assertEq(facet.wrappedNative(), address(0));
    }
}
