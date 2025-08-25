// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { LidoWrapper, IStETH } from "lifi/Periphery/LidoWrapper.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";
import { IERC20 } from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract FailingStETH is ERC20, IStETH {
    constructor() ERC20("stETH", "stETH") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
    function wrap(uint256 amount) external override returns (uint256) { return amount; }
    function unwrap(uint256 amount) external override returns (uint256) { return amount; }
    function transfer(address, uint256) public pure override(ERC20, IERC20) returns (bool) { return false; }
    function transferFrom(address, address, uint256) public pure override(ERC20, IERC20) returns (bool) { return false; }
}

contract MockWstETH is ERC20 {
    constructor() ERC20("wstETH", "wstETH") {}
    function mint(address to, uint256 amount) external { _mint(to, amount); }
}

contract LidoWrapperReturnFalseTest is Test {
    LidoWrapper wrapper;
    FailingStETH steth;
    MockWstETH wsteth;

    function setUp() public {
        wsteth = new MockWstETH();
        steth = new FailingStETH();
        wrapper = new LidoWrapper(address(steth), address(wsteth), address(this));
        steth.mint(address(this), 1 ether);
        steth.approve(address(wrapper), type(uint256).max);
    }

    function test_WrapDoesNotRevertOnFailedTransferFrom() public {
        uint256 balanceBefore = steth.balanceOf(address(this));
        uint256 wrappedAmount = wrapper.wrapStETHToWstETH(1 ether);
        assertEq(wrappedAmount, 0);
        assertEq(steth.balanceOf(address(this)), balanceBefore);
    }
}

