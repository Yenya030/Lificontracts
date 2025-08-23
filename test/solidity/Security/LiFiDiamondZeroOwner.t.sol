// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LiFiDiamond} from "lifi/LiFiDiamond.sol";
import {DiamondCutFacet} from "lifi/Facets/DiamondCutFacet.sol";
import {LibDiamond} from "lifi/Libraries/LibDiamond.sol";
import {OnlyContractOwner} from "lifi/Errors/GenericErrors.sol";

contract LiFiDiamondZeroOwnerTest is Test {
    function test_ConstructorAllowsZeroOwner() public {
        DiamondCutFacet diamondCut = new DiamondCutFacet();
        LiFiDiamond diamond = new LiFiDiamond(address(0), address(diamondCut));

        // Verify owner is zero by reading diamond storage slot
        bytes32 position = keccak256("diamond.standard.diamond.storage");
        bytes32 ownerSlot = bytes32(uint256(position) + 4);
        bytes32 owner = vm.load(address(diamond), ownerSlot);
        assertEq(address(uint160(uint256(owner))), address(0), "owner should be zero");

        // Any attempt to use diamondCut should revert since no contract owner exists
        LibDiamond.FacetCut[] memory cuts = new LibDiamond.FacetCut[](0);
        vm.expectRevert(OnlyContractOwner.selector);
        DiamondCutFacet(address(diamond)).diamondCut(cuts, address(0), "");
    }
}
