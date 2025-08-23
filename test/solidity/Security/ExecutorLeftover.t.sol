// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { Executor } from "lifi/Periphery/Executor.sol";
import { LibSwap } from "lifi/Libraries/LibSwap.sol";
import { TestAMM } from "../utils/TestAMM.sol";
import { TestToken } from "../utils/TestToken.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract ERC20ProxyStub {
    function transferFrom(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        IERC20(token).transferFrom(from, to, amount);
    }
}

contract ExecutorLeftoverTest is Test {
    Executor private executor;
    ERC20ProxyStub private proxy;
    TestAMM private amm;
    TestToken private tokenA;
    TestToken private tokenB;

    function setUp() public {
        proxy = new ERC20ProxyStub();
        executor = new Executor(address(proxy), address(this));
        amm = new TestAMM();
        tokenA = new TestToken("Token A", "TKA", 18);
        tokenB = new TestToken("Token B", "TKB", 18);
        tokenA.mint(address(this), 1_000 ether);
        tokenA.approve(address(proxy), type(uint256).max);
    }

    function test_leftoverTokensRefundedForSingleSwap() public {
        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData({
            callTo: address(amm),
            approveTo: address(amm),
            sendingAssetId: address(tokenA),
            receivingAssetId: address(tokenB),
            fromAmount: 1_000 ether,
            callData: abi.encodeWithSelector(
                amm.partialSwap.selector,
                tokenA,
                1_000 ether,
                tokenB,
                900 ether
            ),
            requiresDeposit: false
        });

        bytes32 txId = keccak256("leftover");
        executor.swapAndExecute(
            txId,
            swapData,
            address(tokenA),
            payable(address(this)),
            1_000 ether
        );

        assertEq(tokenA.balanceOf(address(executor)), 0);
        assertEq(tokenB.balanceOf(address(executor)), 0);
        assertEq(tokenA.balanceOf(address(this)), 200 ether);
        assertEq(tokenB.balanceOf(address(this)), 900 ether);
    }
}

