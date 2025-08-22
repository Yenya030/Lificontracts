// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ReceiverAcrossV3} from "lifi/Periphery/ReceiverAcrossV3.sol";

contract ReceiverAcrossV3ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        ReceiverAcrossV3 r = new ReceiverAcrossV3(address(this), address(0), address(0));
        assertEq(address(r.executor()), address(0));
        assertEq(r.spokepool(), address(0));
    }
}

