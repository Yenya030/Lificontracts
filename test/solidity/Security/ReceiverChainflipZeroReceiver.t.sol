// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {ReceiverChainflip} from "lifi/Periphery/ReceiverChainflip.sol";
import {IExecutor} from "lifi/Interfaces/IExecutor.sol";

contract MockExecutor is IExecutor {
    function swapAndCompleteBridgeTokens(bytes32, LibSwap.SwapData[] calldata, address, address payable)
        external
        payable
        override
    {
        revert("fail");
    }
}

contract ReceiverChainflipZeroReceiverTest is Test {
    ReceiverChainflip internal receiver;
    MockExecutor internal executor;
    bytes32 internal guid = bytes32("12345");
    address constant CHAINFLIP_NATIVE_ADDRESS = 0xEeeeeEeeeEeEeeEeEeEeeEEEeeeeEeeeeeeeEEeE;

    function setUp() public {
        executor = new MockExecutor();
        receiver = new ReceiverChainflip(address(this), address(executor), address(this));
    }

    function test_cfReceiveBurnsFundsOnZeroReceiver() public {
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData({
            callTo: address(0x1),
            approveTo: address(0),
            sendingAssetId: address(0),
            receivingAssetId: address(0),
            fromAmount: 1 ether,
            callData: "",
            requiresDeposit: false
        });

        bytes memory payload = abi.encode(guid, swapData, address(0));
        uint256 preZeroBalance = address(0).balance;
        receiver.cfReceive{value: 1 ether}(0, "", payload, CHAINFLIP_NATIVE_ADDRESS, 1 ether);
        assertEq(address(0).balance, preZeroBalance + 1 ether);
        assertEq(address(receiver).balance, 0);
    }
}
