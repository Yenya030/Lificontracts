// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {DeBridgeDlnFacet} from "lifi/Facets/DeBridgeDlnFacet.sol";
import {IDlnSource} from "lifi/Interfaces/IDlnSource.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";

contract DeBridgeDlnFacetZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroDlnSource() public {
        vm.expectRevert(InvalidConfig.selector);
        new DeBridgeDlnFacet(IDlnSource(address(0)));
    }
}
