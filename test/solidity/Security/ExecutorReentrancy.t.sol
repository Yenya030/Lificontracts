// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { Executor } from "lifi/Periphery/Executor.sol";
import { LibSwap } from "lifi/Libraries/LibSwap.sol";
import { ReentrancyGuard } from "lifi/Helpers/ReentrancyGuard.sol";

contract ERC20ProxyStub {
    function transferFrom(address, address, address, uint256) external {}
}

contract Reenterer {
    Executor public executor;

    constructor(Executor _executor) {
        executor = _executor;
    }

    function reenter() external payable {
        bytes32 dummy = keccak256("reenter");
        LibSwap.SwapData[] memory empty;
        executor.swapAndExecute(dummy, empty, address(0), payable(address(this)), 0);
    }
}

contract ExecutorReentrancyTest is Test {
    Executor private executor;
    Reenterer private reenterer;

    function setUp() public {
        ERC20ProxyStub proxy = new ERC20ProxyStub();
        executor = new Executor(address(proxy), address(this));
        reenterer = new Reenterer(executor);
    }

    function testRevert_ReentrancyInSwap() public {
        LibSwap.SwapData[] memory swaps = new LibSwap.SwapData[](1);
        swaps[0] = LibSwap.SwapData({
            callTo: address(reenterer),
            approveTo: address(0),
            sendingAssetId: address(0),
            receivingAssetId: address(0),
            fromAmount: 1,
            callData: abi.encodeWithSignature("reenter()"),
            requiresDeposit: false
        });

        bytes32 txId = keccak256("tx");
        vm.expectRevert(ReentrancyGuard.ReentrancyError.selector);
        executor.swapAndExecute{value: 1}(txId, swaps, address(0), payable(address(this)), 0);
    }
}

