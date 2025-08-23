// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { RelayFacet } from "lifi/Facets/RelayFacet.sol";
import { ILiFi } from "lifi/Interfaces/ILiFi.sol";
import { ReentrancyGuard } from "lifi/Helpers/ReentrancyGuard.sol";
import { ECDSA } from "solady/utils/ECDSA.sol";

contract ReentrantRelayReceiver {
    RelayFacet public relay;
    ILiFi.BridgeData public bridgeData;
    RelayFacet.RelayData public relayData;
    bool internal reentered;

    function setData(
        RelayFacet _relay,
        ILiFi.BridgeData calldata _bridgeData,
        RelayFacet.RelayData calldata _relayData
    ) external {
        relay = _relay;
        bridgeData = _bridgeData;
        relayData = _relayData;
    }

    fallback() external payable {
        if (!reentered) {
            reentered = true;
            ILiFi.BridgeData memory bd = bridgeData;
            RelayFacet.RelayData memory rd = relayData;
            relay.startBridgeTokensViaRelay{ value: msg.value }(bd, rd);
        }
    }
}

contract RelayFacetReentrancyStartTest is Test {
    RelayFacet relayFacet;
    ReentrantRelayReceiver receiver;
    address relaySolver;
    uint256 solverKey;

    function setUp() public {
        solverKey = 0xBEEF;
        relaySolver = vm.addr(solverKey);
        receiver = new ReentrantRelayReceiver();
        relayFacet = new RelayFacet(address(receiver), relaySolver);
    }

    function test_ReentrancyOnStartBridgeTokensViaRelayIsBlocked() public {
        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "Relay",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(0xBEEF),
            minAmount: 1 ether,
            destinationChainId: 2,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        RelayFacet.RelayData memory relayData = RelayFacet.RelayData({
            requestId: bytes32("req"),
            nonEVMReceiver: bytes32(0),
            receivingAssetId: bytes32(0),
            signature: ""
        });

        bytes32 message = ECDSA.toEthSignedMessageHash(
            keccak256(
                abi.encodePacked(
                    relayData.requestId,
                    block.chainid,
                    bytes32(uint256(uint160(address(relayFacet)))),
                    bytes32(uint256(uint160(address(0)))),
                    uint256(2),
                    bytes32(uint256(uint160(address(0xBEEF)))),
                    bytes32(0)
                )
            )
        );
        (uint8 v, bytes32 r, bytes32 s) = vm.sign(solverKey, message);
        relayData.signature = abi.encodePacked(r, s, v);

        receiver.setData(relayFacet, bridgeData, relayData);

                vm.expectRevert();
        relayFacet.startBridgeTokensViaRelay{ value: 1 ether }(bridgeData, relayData);
    }
}

