// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LiFiDiamond} from "lifi/LiFiDiamond.sol";
import {DiamondCutFacet} from "lifi/Facets/DiamondCutFacet.sol";
import {LibDiamond} from "lifi/Libraries/LibDiamond.sol";

contract LiFiDiamondZeroOwnerTest is Test {
    function test_ConstructorAllowsZeroOwner() public {
        DiamondCutFacet diamondCut = new DiamondCutFacet();
        LiFiDiamond diamond = new LiFiDiamond(address(0), address(diamondCut));

        bytes32 position = keccak256("diamond.standard.diamond.storage");
        address owner = address(uint160(uint256(vm.load(address(diamond), position))));
        assertEq(owner, address(0), "owner should be zero");

        LibDiamond.FacetCut[] memory cut;
        vm.expectRevert();
        DiamondCutFacet(address(diamond)).diamondCut(cut, address(0), "");
    }
}
