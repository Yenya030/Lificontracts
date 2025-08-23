// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GasZipPeriphery} from "lifi/Periphery/GasZipPeriphery.sol";

contract GasZipPeripheryZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        GasZipPeriphery periphery = new GasZipPeriphery(address(0), address(0), address(this));
        assertEq(address(periphery.gasZipRouter()), address(0));
        assertEq(address(periphery.liFiDEXAggregator()), address(0));
    }
}
