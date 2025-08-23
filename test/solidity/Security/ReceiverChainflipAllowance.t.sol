// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {ReceiverChainflip} from "lifi/Periphery/ReceiverChainflip.sol";
import {Executor} from "lifi/Periphery/Executor.sol";
import {ERC20Proxy} from "lifi/Periphery/ERC20Proxy.sol";
import {ERC20} from "solmate/tokens/ERC20.sol";

contract MockToken is ERC20("Mock", "M", 18) {
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract ReceiverChainflipAllowanceTest is Test {
    ReceiverChainflip internal receiver;
    Executor internal executor;
    ERC20Proxy internal erc20Proxy;
    MockToken internal token;
    address internal chainflipVault = address(0x123);
    address internal receiverAddress = address(0x456);
    bytes32 internal guid = bytes32("12345");

    function setUp() public {
        token = new MockToken();
        erc20Proxy = new ERC20Proxy(address(this));
        executor = new Executor(address(erc20Proxy), address(this));
        receiver = new ReceiverChainflip(address(this), address(executor), chainflipVault);
    }

    function test_AllowanceResetsAfterSuccess() public {
        // simulate bridged tokens
        token.mint(address(receiver), 100 ether);

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](1);
        swapData[0] = LibSwap.SwapData({
            callTo: address(token),
            approveTo: address(token),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: 100 ether,
            callData: abi.encodeWithSelector(token.transfer.selector, receiverAddress, 100 ether),
            requiresDeposit: false
        });

        bytes memory payload = abi.encode(guid, swapData, receiverAddress);

        vm.prank(chainflipVault);
        receiver.cfReceive(0, "", payload, address(token), 100 ether);

        uint256 allowance = token.allowance(address(receiver), address(executor));
        assertEq(allowance, 0);
    }
}
