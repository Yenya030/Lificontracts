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

contract MockStETH is ERC20, IStETH {
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
}

contract LidoWrapperSweepTest is Test {
    LidoWrapper wrapper;
    MockStETH steth;
    MockWstETH wsteth;
    address victim = address(0x1);

    function setUp() public {
        wsteth = new MockWstETH();
        steth = new MockStETH(wsteth);
        wrapper = new LidoWrapper(address(steth), address(wsteth), address(this));

        steth.mint(victim, 50 ether);
        vm.prank(victim);
        steth.transfer(address(wrapper), 50 ether);

        steth.mint(address(this), 10 ether);
        steth.approve(address(wrapper), type(uint256).max);
    }

    function testWrapSweepsExistingBalance() public {
        wrapper.wrapStETHToWstETH(10 ether);
        assertEq(wsteth.balanceOf(address(this)), 60 ether);
    }
}

