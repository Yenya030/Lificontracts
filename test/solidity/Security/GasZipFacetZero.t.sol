// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GasZipFacet} from "lifi/Facets/GasZipFacet.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";

contract GasZipFacetZeroTest is Test {
    function test_constructor_reverts_on_zero_router() public {
        vm.expectRevert(InvalidConfig.selector);
        new GasZipFacet(address(0));
    }
}
