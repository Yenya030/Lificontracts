// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ReceiverStargateV2} from "lifi/Periphery/ReceiverStargateV2.sol";

contract ReceiverStargateV2ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        ReceiverStargateV2 r = new ReceiverStargateV2(
            address(this),
            address(0),
            address(0),
            address(0),
            0
        );
        assertEq(address(r.executor()), address(0));
        assertEq(address(r.tokenMessaging()), address(0));
        assertEq(r.endpointV2(), address(0));
    }
}

