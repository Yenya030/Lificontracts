// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";
import {LiFiDEXAggregator} from "lifi/Periphery/LiFiDEXAggregator.sol";

contract ReentrantToken is IERC20 {
    string public name = "Reentrant Token";
    string public symbol = "RNT";
    uint8 public decimals = 18;
    uint256 public override totalSupply;
    mapping(address => uint256) public override balanceOf;
    mapping(address => mapping(address => uint256)) public override allowance;
    LiFiDEXAggregator public aggregator;

    constructor(LiFiDEXAggregator _aggregator) {
        aggregator = _aggregator;
    }

    function mint(address to, uint256 amount) external {
        balanceOf[to] += amount;
        totalSupply += amount;
        emit Transfer(address(0), to, amount);
    }

    function approve(address spender, uint256 amount) external override returns (bool) {
        allowance[msg.sender][spender] = amount;
        emit Approval(msg.sender, spender, amount);
        return true;
    }

    function transfer(address to, uint256 amount) external override returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        emit Transfer(msg.sender, to, amount);
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external override returns (bool) {
        if (allowance[from][msg.sender] != type(uint256).max) {
            allowance[from][msg.sender] -= amount;
        }
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        emit Transfer(from, to, amount);
        aggregator.pancakeV3SwapCallback(1, 0, abi.encode(address(this)));
        return true;
    }
}

contract LiFiDEXAggregatorReentrancyTest is Test {
    LiFiDEXAggregator internal aggregator;
    ReentrantToken internal token;

    function setUp() public {
        address[] memory privileged = new address[](1);
        privileged[0] = address(this);
        aggregator = new LiFiDEXAggregator(address(0), privileged, address(this));
        token = new ReentrantToken(aggregator);
        token.mint(address(this), 1e18);
        token.approve(address(aggregator), type(uint256).max);
    }

    function testRevert_ReentrancyDuringTransferFrom() public {
        vm.expectRevert(LiFiDEXAggregator.UniswapV3SwapCallbackUnknownSource.selector);
        vm.prank(address(aggregator));
        token.transferFrom(address(this), address(aggregator), 1e18);
    }
}

