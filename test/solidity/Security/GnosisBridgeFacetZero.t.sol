// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GnosisBridgeFacet} from "lifi/Facets/GnosisBridgeFacet.sol";
import {IGnosisBridgeRouter} from "lifi/Interfaces/IGnosisBridgeRouter.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";

contract GnosisBridgeFacetZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroRouterAddress() public {
        vm.expectRevert(InvalidConfig.selector);
        new GnosisBridgeFacet(IGnosisBridgeRouter(address(0)));
    }
}
