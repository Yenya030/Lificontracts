// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SwapperV2} from "lifi/Helpers/SwapperV2.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";

contract SwapperV2Harness is SwapperV2 {
    function runDepositAndSwap(
        LibSwap.SwapData[] calldata swaps
    ) external payable {
        _depositAndSwap(bytes32(0), 0, swaps, payable(msg.sender));
    }
}

contract SwapperV2FetchBalancesRevertsTest is Test {
    SwapperV2Harness internal swapper;

    function setUp() public {
        swapper = new SwapperV2Harness();
    }

    function test_fetchBalancesRevertsOnMsgValueNativeReceivingAsset() public {
        LibSwap.SwapData[] memory swaps = new LibSwap.SwapData[](1);
        swaps[0] = LibSwap.SwapData({
            callTo: address(0x1),
            approveTo: address(0x1),
            sendingAssetId: address(0x2),
            receivingAssetId: address(0),
            fromAmount: 1 ether,
            callData: bytes(""),
            requiresDeposit: false
        });

        vm.expectRevert();
        swapper.runDepositAndSwap{value: 1}(swaps);
    }
}

