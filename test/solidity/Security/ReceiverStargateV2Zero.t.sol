// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ReceiverStargateV2} from "lifi/Periphery/ReceiverStargateV2.sol";

contract ReceiverStargateV2ZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        ReceiverStargateV2 receiver = new ReceiverStargateV2(address(this), address(0), address(0), address(0), 0);
        assertEq(address(receiver.executor()), address(0));
        assertEq(address(receiver.tokenMessaging()), address(0));
        assertEq(receiver.endpointV2(), address(0));
    }
}
