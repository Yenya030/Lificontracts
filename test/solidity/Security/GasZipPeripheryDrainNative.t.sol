// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { GasZipPeriphery } from "lifi/Periphery/GasZipPeriphery.sol";
import { IGasZip } from "lifi/Interfaces/IGasZip.sol";

contract MockGasZipRouter is IGasZip {
    event Deposit(uint256 destinationChains, bytes32 to, uint256 amount);

    function deposit(uint256 destinationChains, bytes32 to) external payable {
        address receiver = address(uint160(uint256(to)));
        payable(receiver).transfer(msg.value);
        emit Deposit(destinationChains, to, msg.value);
    }
}

contract GasZipPeripheryDrainNativeTest is Test {
    GasZipPeriphery gasZip;
    MockGasZipRouter router;
    address aggregator = address(0xdead);
    address attacker = address(0xbad);

    function setUp() public {
        router = new MockGasZipRouter();
        gasZip = new GasZipPeriphery(address(router), aggregator, address(this));
        vm.deal(address(gasZip), 1 ether);
    }

    function test_DepositToGasZipNativeDrainsStuckEther() public {
        IGasZip.GasZipData memory data = IGasZip.GasZipData({
            receiverAddress: bytes32(uint256(uint160(attacker))),
            destinationChains: 0
        });

        uint256 attackerBalanceBefore = attacker.balance;
        vm.prank(attacker);
        gasZip.depositToGasZipNative(data, 1 ether);

        assertEq(address(gasZip).balance, 0);
        assertEq(attacker.balance, attackerBalanceBefore + 1 ether);
    }
}
