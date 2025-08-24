// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {MayanFacet} from "lifi/Facets/MayanFacet.sol";
import {IMayan} from "lifi/Interfaces/IMayan.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract MayanMock is IMayan {
    function forwardEth(address, bytes calldata) external payable {}

    function forwardERC20(
        address,
        uint256,
        IMayan.PermitParams calldata,
        address,
        bytes calldata
    ) external payable {}
}

contract MayanFacetDustTest is Test {
    MayanFacet facet;
    MayanMock mayan;

    receive() external payable {}

    function setUp() public {
        mayan = new MayanMock();
        facet = new MayanFacet(IMayan(address(mayan)));
    }

    function test_NormalizationRefundsExcess() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32(0),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(this),
            minAmount: 1 ether + 5,
            destinationChainId: block.chainid + 1,
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

        facet.startBridgeTokensViaMayan{value: 1 ether + 5}(bridgeData, mayanData);

        assertEq(address(facet).balance, 0);
        assertEq(address(mayan).balance, 1 ether);
    }
}

