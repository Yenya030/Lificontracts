// SPDX-License-Identifier: Unlicense
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { CalldataVerificationFacet } from "lifi/Facets/CalldataVerificationFacet.sol";
import { GenericSwapFacetV3 } from "lifi/Facets/GenericSwapFacetV3.sol";
import { LibSwap } from "lifi/Libraries/LibSwap.sol";
import { InvalidCallData } from "lifi/Errors/GenericErrors.sol";

contract CalldataVerificationFacetInvalidTest is Test {
    CalldataVerificationFacet internal facet;

    function setUp() public {
        facet = new CalldataVerificationFacet();
    }

    function test_RevertsOnInvalidGenericSwapCalldata() public {
        LibSwap.SwapData memory swapData = LibSwap.SwapData({
            callTo: address(1),
            approveTo: address(1),
            sendingAssetId: address(1),
            receivingAssetId: address(2),
            fromAmount: 1,
            callData: "",
            requiresDeposit: false
        });

        bytes memory callData = abi.encodeWithSelector(
            GenericSwapFacetV3.swapTokensSingleV3ERC20ToERC20.selector,
            bytes32("id"),
            "",
            "",
            payable(address(0x1234)),
            1,
            swapData
        );

        assembly {
            mstore(callData, 483)
        }

        vm.expectRevert(InvalidCallData.selector);
        facet.extractGenericSwapParameters(callData);
    }
}
