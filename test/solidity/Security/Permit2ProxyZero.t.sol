// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Permit2Proxy} from "lifi/Periphery/Permit2Proxy.sol";
import {ISignatureTransfer} from "permit2/interfaces/ISignatureTransfer.sol";

contract Permit2ProxyZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        Permit2Proxy proxy = new Permit2Proxy(
            address(0),
            ISignatureTransfer(address(0)),
            address(0)
        );
        assertEq(proxy.LIFI_DIAMOND(), address(0));
        assertEq(address(proxy.PERMIT2()), address(0));
        assertEq(proxy.owner(), address(0));
    }
}

