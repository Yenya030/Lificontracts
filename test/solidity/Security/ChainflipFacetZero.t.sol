// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ChainflipFacet} from "lifi/Facets/ChainflipFacet.sol";
import {IChainflipVault} from "lifi/Interfaces/IChainflip.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";

contract ChainflipFacetZeroVaultTest is Test {
    function test_ConstructorRevertsOnZeroVault() public {
        vm.expectRevert(InvalidConfig.selector);
        new ChainflipFacet(IChainflipVault(address(0)));
    }
}
