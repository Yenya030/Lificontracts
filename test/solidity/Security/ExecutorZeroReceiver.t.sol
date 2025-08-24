// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {Executor} from "lifi/Periphery/Executor.sol";
import {ERC20Proxy} from "lifi/Periphery/ERC20Proxy.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";
import {InvalidReceiver} from "lifi/Errors/GenericErrors.sol";

contract TestToken is ERC20("TestToken", "TT", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MockDex {
    function swap() external {}
}

contract ExecutorZeroReceiverTest is Test {
    Executor internal executor;
    ERC20Proxy internal proxy;
    TestToken internal token;
    MockDex internal dex;

    function setUp() public {
        token = new TestToken();
        token.mint(address(this), 1 ether);
        proxy = new ERC20Proxy(address(this));
        executor = new Executor(address(proxy), address(this));
        proxy.setAuthorizedCaller(address(executor), true);
        dex = new MockDex();
    }

    function test_swapAndExecuteRevertsOnZeroReceiver() public {
        uint256 amount = 1 ether;
        token.approve(address(proxy), amount);

        LibSwap.SwapData[] memory swaps = new LibSwap.SwapData[](1);
        swaps[0] = LibSwap.SwapData({
            callTo: address(dex),
            approveTo: address(dex),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: amount,
            callData: abi.encodeWithSelector(MockDex.swap.selector),
            requiresDeposit: false
        });

        vm.expectRevert(InvalidReceiver.selector);
        executor.swapAndExecute(
            bytes32("tx"),
            swaps,
            address(token),
            payable(address(0)),
            amount
        );
    }
}

