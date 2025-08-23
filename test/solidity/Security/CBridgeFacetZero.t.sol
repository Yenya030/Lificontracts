// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {CBridgeFacet} from "lifi/Facets/CBridgeFacet.sol";
import {ICBridge} from "lifi/Interfaces/ICBridge.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract CBridgeFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroCBridgeAddress() public {
        CBridgeFacet facet = new CBridgeFacet(ICBridge(address(0)));

        vm.deal(address(this), 1 ether);

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "cBridge",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: block.chainid + 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        CBridgeFacet.CBridgeData memory cData = CBridgeFacet.CBridgeData({maxSlippage: 0, nonce: 0});

        uint256 balanceBefore = address(this).balance;
        vm.expectRevert();
        facet.startBridgeTokensViaCBridge{value: 1}(bridgeData, cData);
        assertEq(address(this).balance, balanceBefore, "balance unchanged after revert");
    }
}
