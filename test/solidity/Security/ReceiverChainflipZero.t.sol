// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ReceiverChainflip} from "lifi/Periphery/ReceiverChainflip.sol";
import {InvalidConfig} from "lifi/Errors/GenericErrors.sol";

contract ReceiverChainflipZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroAddresses() public {
        vm.expectRevert(InvalidConfig.selector);
        new ReceiverChainflip(address(0), address(0), address(0));
    }
}

