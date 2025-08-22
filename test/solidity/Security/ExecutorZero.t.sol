// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Executor} from "lifi/Periphery/Executor.sol";

contract ExecutorZeroAddressTest is Test {
    function test_ConstructorAllowsZeroProxy() public {
        Executor e = new Executor(address(0), address(this));
        assertEq(address(e.erc20Proxy()), address(0));
    }
}

