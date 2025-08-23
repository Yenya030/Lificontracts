// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {AllBridgeFacet} from "lifi/Facets/AllBridgeFacet.sol";
import {IAllBridge} from "lifi/Interfaces/IAllBridge.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";

contract AllBridgeFacetZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroAllBridge() public {
        vm.expectRevert(InvalidConfig.selector);
        new AllBridgeFacet(IAllBridge(address(0)));
    }
}
