// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LiFiDEXAggregator} from "lifi/Periphery/LiFiDEXAggregator.sol";

contract LiFiDexAggregatorZeroAddressTest is Test {
    function test_ConstructorAllowsZeroBentoBox() public {
        address[] memory priviledged;
        LiFiDEXAggregator agg = new LiFiDEXAggregator(address(0), priviledged, address(this));
        assertEq(address(agg.BENTO_BOX()), address(0));
    }
}
