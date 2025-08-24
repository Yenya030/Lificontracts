// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {AcrossFacetPacked} from "lifi/Facets/AcrossFacetPacked.sol";
import {IAcrossSpokePool} from "lifi/Interfaces/IAcrossSpokePool.sol";

contract AcrossFacetPackedZeroAddressTest is Test {
    AcrossFacetPacked facet;

    function setUp() public {
        facet = new AcrossFacetPacked(IAcrossSpokePool(address(0)), address(0), address(this));
    }

    function test_ConstructorAllowsZeroAddresses() public {
        assertTrue(address(facet) != address(0));
    }

    function test_BridgeRevertsWithZeroConfig() public {
        vm.expectRevert();
        facet.startBridgeTokensViaAcrossNativeMin{value: 1 ether}(bytes32("tx"), address(0x1), 1, 0, 0, "", 0);
    }
}
