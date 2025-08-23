// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {TokenWrapper} from "lifi/Periphery/TokenWrapper.sol";

contract TokenWrapperZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroWrappedToken() public {
        vm.expectRevert();
        new TokenWrapper(address(0), address(this));
    }
}
