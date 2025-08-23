// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {FeeCollector} from "lifi/Periphery/FeeCollector.sol";
import {LibAsset} from "lifi/Libraries/LibAsset.sol";

contract ReentrantCaller {
    FeeCollector collector;
    address integrator;

    constructor(FeeCollector _collector) {
        collector = _collector;
        integrator = address(this);
    }

    function attack() external payable {
        collector.collectNativeFees{value: msg.value}(1 ether, 1 ether, integrator);
    }

    receive() external payable {
        // reenter during refund of surplus ETH
        collector.withdrawIntegratorFees(LibAsset.NULL_ADDRESS);
    }
}

contract FeeCollectorReentrancyTest is Test {
    FeeCollector internal collector;
    ReentrantCaller internal attacker;

    function setUp() public {
        collector = new FeeCollector(address(this));
        attacker = new ReentrantCaller(collector);
    }

    function test_ReentrancyDoesNotDrainFees() public {
        vm.deal(address(attacker), 3 ether);
        vm.prank(address(attacker));
        attacker.attack{value: 3 ether}();

        // integrator fees withdrawn during reentrancy, lifi fees remain
        assertEq(collector.getLifiTokenBalance(LibAsset.NULL_ADDRESS), 1 ether);
        assertEq(address(collector).balance, 1 ether);
    }
}
