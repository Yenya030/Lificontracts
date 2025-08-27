// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { ReceiverChainflip } from "lifi/Periphery/ReceiverChainflip.sol";
import { InvalidConfig } from "lifi/Errors/GenericErrors.sol";

contract ReceiverChainflipConstructorTest is Test {
    function test_RevertsOnZeroAddresses() public {
        vm.expectRevert(InvalidConfig.selector);
        new ReceiverChainflip(address(0), address(1), address(1));

        vm.expectRevert(InvalidConfig.selector);
        new ReceiverChainflip(address(1), address(0), address(1));

        vm.expectRevert(InvalidConfig.selector);
        new ReceiverChainflip(address(1), address(1), address(0));
    }
}
