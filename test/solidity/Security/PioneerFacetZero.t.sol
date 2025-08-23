// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {PioneerFacet} from "lifi/Facets/PioneerFacet.sol";
import {ILiFi} from "lifi/Interfaces/ILiFi.sol";
import {InvalidConfig, InvalidCallData} from "lifi/Errors/GenericErrors.sol";

contract PioneerFacetZeroAddressTest is Test {
    function test_ConstructorRevertsOnZeroPioneerAddress() public {
        vm.expectRevert(InvalidConfig.selector);
        new PioneerFacet(payable(address(0)));
    }

    function test_StartBridgeRevertsOnZeroRefundAddress() public {
        PioneerFacet facet = new PioneerFacet(payable(address(1)));

        ILiFi.BridgeData memory data = ILiFi.BridgeData({
            transactionId: bytes32(""),
            bridge: "",
            integrator: "",
            referrer: address(0),
            sendingAssetId: address(0),
            receiver: address(1),
            minAmount: 1,
            destinationChainId: 1,
            hasSourceSwaps: false,
            hasDestinationCall: false
        });

        PioneerFacet.PioneerData memory pData = PioneerFacet.PioneerData({
            refundAddress: payable(address(0))
        });

        vm.expectRevert(InvalidCallData.selector);
        facet.startBridgeTokensViaPioneer{value:1}(data, pData);
    }
}
