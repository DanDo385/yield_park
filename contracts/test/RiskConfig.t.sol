// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {RiskConfig} from "../src/core/RiskConfig.sol";

contract RiskConfigTest is Test {
    RiskConfig risk;
    address admin = address(this);

    function setUp() public {
        risk = new RiskConfig(admin, 3000, 4000, 2000);
    }

    function testInitialCaps() public view {
        assertEq(risk.maxPerAdapterBps(), 3000);
        assertEq(risk.maxPerAssetBps(), 4000);
        assertEq(risk.maxShiftPerRebalanceBps(), 2000);
    }

    function testSetCaps() public {
        risk.setCaps(2500, 3500, 1500);
        assertEq(risk.maxPerAdapterBps(), 2500);
        assertEq(risk.maxPerAssetBps(), 3500);
        assertEq(risk.maxShiftPerRebalanceBps(), 1500);
    }

    function testOnlyManagerCanSetCaps() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        risk.setCaps(2500, 3500, 1500);
    }
}
