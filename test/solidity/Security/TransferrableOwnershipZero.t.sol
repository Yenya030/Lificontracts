// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {TransferrableOwnership} from "../../../src/Helpers/TransferrableOwnership.sol";

contract TransferrableOwnershipZeroOwnerTest is Test {
    function testInitialOwnerZeroAllowed() public {
        TransferrableOwnership t = new TransferrableOwnership(address(0));
        assertEq(t.owner(), address(0));
    }
}
