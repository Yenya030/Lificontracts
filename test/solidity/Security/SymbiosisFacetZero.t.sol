// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {SymbiosisFacet} from "lifi/Facets/SymbiosisFacet.sol";
import {ISymbiosisMetaRouter} from "lifi/Interfaces/ISymbiosisMetaRouter.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";

contract SymbiosisFacetZeroAddressTest is Test {
    function test_ConstructorAllowsZeroAddresses() public {
        SymbiosisFacet facet = new SymbiosisFacet(ISymbiosisMetaRouter(address(0)), address(0));

        vm.deal(address(this), 1 ether);

        ILiFi.BridgeData memory bridgeData = ILiFi.BridgeData({
            transactionId: bytes32("tx"),
            bridge: "symbiosis",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: block.chainid + 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        address[] memory approved;
        SymbiosisFacet.SymbiosisData memory sData = SymbiosisFacet.SymbiosisData({
            firstSwapCalldata: "",
            secondSwapCalldata: "",
            intermediateToken: address(0),
            firstDexRouter: address(0),
            secondDexRouter: address(0),
            approvedTokens: approved,
            callTo: address(0),
            callData: ""
        });

        uint256 balanceBefore = address(this).balance;
        vm.expectRevert();
        facet.startBridgeTokensViaSymbiosis{value: 1}(bridgeData, sData);
        assertEq(address(this).balance, balanceBefore, "balance unchanged after revert");
    }
}
