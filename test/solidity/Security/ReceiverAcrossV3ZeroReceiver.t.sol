// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {ReceiverAcrossV3} from "lifi/Periphery/ReceiverAcrossV3.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {IExecutor} from "lifi/Interfaces/IExecutor.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract TestToken is ERC20("TestToken", "TT", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockExecutor is IExecutor {
    function swapAndCompleteBridgeTokens(
        bytes32,
        LibSwap.SwapData[] calldata,
        address,
        address payable
    ) external payable override {
        revert("fail");
    }
}

contract ReceiverAcrossV3ZeroReceiverTest is Test {
    ReceiverAcrossV3 internal receiver;
    MockExecutor internal executor;
    TestToken internal token;

    function setUp() public {
        executor = new MockExecutor();
        receiver = new ReceiverAcrossV3(address(this), address(executor), address(this));
        token = new TestToken();
    }

    function test_handleV3AcrossMessageBurnsFundsOnZeroReceiver() public {
        uint256 amount = 1 ether;
        token.mint(address(this), amount);
        token.transfer(address(receiver), amount);

        LibSwap.SwapData[] memory swaps = new LibSwap.SwapData[](0);
        bytes memory payload = abi.encode(bytes32("tx"), swaps, address(0));

        uint256 preZero = token.balanceOf(address(0));
        receiver.handleV3AcrossMessage(address(token), amount, address(0), payload);
        assertEq(token.balanceOf(address(0)), preZero + amount);
        assertEq(token.balanceOf(address(receiver)), 0);
    }
}

