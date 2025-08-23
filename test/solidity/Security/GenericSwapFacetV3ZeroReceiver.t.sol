// SPDX-License-Identifier: UNLICENSED
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import { GenericSwapFacetV3 } from "lifi/Facets/GenericSwapFacetV3.sol";
import { LibSwap } from "lifi/Libraries/LibSwap.sol";
import { LibAllowList } from "lifi/Libraries/LibAllowList.sol";

contract TestGenericSwapFacetV3 is GenericSwapFacetV3 {
    constructor() GenericSwapFacetV3(address(0)) {}
    function addDex(address _dex) external { LibAllowList.addAllowedContract(_dex); }
    function setFunctionApprovalBySignature(bytes4 _sig) external { LibAllowList.addAllowedSelector(_sig); }
}

contract DummyDex {
    function swap(address, address, uint256) external {}
}

// ERC20 token that allows transfers to the zero address
contract LooseToken {
    string public constant name = "Loose";
    string public constant symbol = "LOOSE";
    uint8 public constant decimals = 18;
    mapping(address => uint256) public balanceOf;
    mapping(address => mapping(address => uint256)) public allowance;

    constructor(uint256 supply) { balanceOf[msg.sender] = supply; }

    function approve(address spender, uint256 amount) external returns (bool) {
        allowance[msg.sender][spender] = amount;
        return true;
    }

    function transfer(address to, uint256 amount) external returns (bool) {
        balanceOf[msg.sender] -= amount;
        balanceOf[to] += amount;
        return true;
    }

    function transferFrom(address from, address to, uint256 amount) external returns (bool) {
        uint256 allowed = allowance[from][msg.sender];
        require(allowed >= amount, "allowance");
        allowance[from][msg.sender] = allowed - amount;
        balanceOf[from] -= amount;
        balanceOf[to] += amount;
        return true;
    }
}

contract GenericSwapFacetV3ZeroReceiverTest is Test {
    TestGenericSwapFacetV3 facet;
    DummyDex dex;
    LooseToken token;

    function setUp() public {
        facet = new TestGenericSwapFacetV3();
        dex = new DummyDex();
        token = new LooseToken(1 ether);

        facet.addDex(address(dex));
        facet.setFunctionApprovalBySignature(DummyDex.swap.selector);

        token.approve(address(facet), type(uint256).max);
    }

    function test_ZeroReceiverBurnsTokens() public {
        LibSwap.SwapData memory swapData = LibSwap.SwapData({
            callTo: address(dex),
            approveTo: address(dex),
            sendingAssetId: address(token),
            receivingAssetId: address(token),
            fromAmount: 1 ether,
            callData: abi.encodeWithSelector(DummyDex.swap.selector, address(token), address(token), 1 ether),
            requiresDeposit: true
        });

        facet.swapTokensSingleV3ERC20ToERC20(
            bytes32("tx"),
            "",
            "",
            payable(address(0)),
            0,
            swapData
        );

        assertEq(token.balanceOf(address(0)), 1 ether);
        assertEq(token.balanceOf(address(facet)), 0);
    }
}

