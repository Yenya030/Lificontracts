// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {OFTComposeMsgCodec} from "lifi/Libraries/OFTComposeMsgCodec.sol";
import {ReceiverStargateV2} from "lifi/Periphery/ReceiverStargateV2.sol";
import {IExecutor} from "lifi/Interfaces/IExecutor.sol";
import {ITokenMessaging} from "lifi/Interfaces/IStargate.sol";

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

contract MockTokenMessaging is ITokenMessaging {
    mapping(address => uint16) internal ids;

    function setAssetId(address token, uint16 id) external {
        ids[token] = id;
    }

    function assetIds(address tokenAddress) external view override returns (uint16) {
        return ids[tokenAddress];
    }

    function stargateImpls(uint16) external pure override returns (address) {
        return address(0);
    }
}

contract MockPool {
    function token() external pure returns (address tokenAddress) {
        tokenAddress = address(0);
    }
}

contract ReceiverStargateV2ZeroReceiverTest is Test {
    ReceiverStargateV2 internal receiver;
    MockExecutor internal executor;
    MockTokenMessaging internal tokenMessaging;
    MockPool internal pool;
    bytes32 internal guid = bytes32("12345");

    function setUp() public {
        executor = new MockExecutor();
        tokenMessaging = new MockTokenMessaging();
        pool = new MockPool();
        tokenMessaging.setAssetId(address(pool), 1);

        receiver = new ReceiverStargateV2(
            address(this),
            address(executor),
            address(tokenMessaging),
            address(this),
            0
        );
    }

    function test_lzComposeBurnsFundsOnZeroReceiver() public {
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
        bytes memory composeMsg = abi.encodePacked(bytes32(0), payload);
        bytes memory message = OFTComposeMsgCodec.encode(0, 0, 1 ether, composeMsg);

        uint256 preZeroBalance = address(0).balance;
        receiver.lzCompose{value: 1 ether}(
            address(pool),
            bytes32(0),
            message,
            address(0),
            bytes("")
        );
        assertEq(address(0).balance, preZeroBalance + 1 ether);
        assertEq(address(receiver).balance, 0);
    }
}

