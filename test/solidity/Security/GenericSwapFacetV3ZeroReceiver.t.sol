// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GenericSwapFacetV3} from "lifi/Facets/GenericSwapFacetV3.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {TestToken} from "../utils/TestToken.sol";

contract DummyDex {
    function noop() external {}
}

contract GenericSwapFacetV3Harness is GenericSwapFacetV3 {
    constructor(address _nativeAddress) GenericSwapFacetV3(_nativeAddress) {}

    function addAllowedContract(address _contract) external {
        LibAllowList.addAllowedContract(_contract);
    }

    function addAllowedSelector(bytes4 _selector) external {
        LibAllowList.addAllowedSelector(_selector);
    }
}

contract GenericSwapFacetV3ZeroReceiverTest is Test {
    GenericSwapFacetV3Harness facet;
    DummyDex dex;
    TestToken token;

    function setUp() public {
        facet = new GenericSwapFacetV3Harness(address(0));
        dex = new DummyDex();
        token = new TestToken("Token", "TKN", 18);

        facet.addAllowedContract(address(dex));
        facet.addAllowedSelector(DummyDex.noop.selector);

        // Pre-fund facet with native tokens
        vm.deal(address(facet), 1 ether);
    }

    function test_SendToZeroBurnsETH() public {
        LibSwap.SwapData memory swap = LibSwap.SwapData({
            callTo: address(dex),
            approveTo: address(dex),
            sendingAssetId: address(token),
            receivingAssetId: address(0),
            fromAmount: 0,
            callData: abi.encodeWithSelector(DummyDex.noop.selector),
            requiresDeposit: false
        });

        facet.swapTokensSingleV3ERC20ToNative(
            bytes32(0),
            "",
            "",
            payable(address(0)),
            0,
            swap
        );

        assertEq(address(facet).balance, 0);
    }
}
