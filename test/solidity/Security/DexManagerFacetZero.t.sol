// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {DexManagerFacet} from "lifi/Facets/DexManagerFacet.sol";
import {InvalidContract} from "lifi/Errors/GenericErrors.sol";

contract DexManagerFacetZeroAddressTest is Test {
    function test_addDexRevertsOnZeroAddress() public {
        DexManagerFacet facet = new DexManagerFacet();
        bytes32 namespace = keccak256("com.lifi.library.access.management");
        bytes32 selectorSlot = keccak256(abi.encode(DexManagerFacet.addDex.selector, uint256(namespace)));
        bytes32 accessSlot = keccak256(abi.encode(address(this), selectorSlot));
        vm.store(address(facet), accessSlot, bytes32(uint256(1)));
        vm.expectRevert(InvalidContract.selector);
        facet.addDex(address(0));
    }
}

