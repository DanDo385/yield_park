// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {StrategyRegistry} from "../src/core/StrategyRegistry.sol";
import {MockYieldAdapter} from "../src/adapters/MockYieldAdapter.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";

contract StrategyRegistryTest is Test {
    StrategyRegistry registry;
    MockERC20 usdc;
    MockYieldAdapter adapter;
    address admin = address(this);

    function setUp() public {
        usdc = new MockERC20("mUSDC", "mUSDC", 6);
        registry = new StrategyRegistry(admin);
        adapter = new MockYieldAdapter(usdc, address(this));
    }

    function testAddAdapter() public {
        registry.addAdapter(address(adapter));
        assertTrue(registry.isAdapter(address(adapter)));
    }

    function testRemoveAdapter() public {
        registry.addAdapter(address(adapter));
        registry.removeAdapter(address(adapter));
        assertFalse(registry.isAdapter(address(adapter)));
    }

    function testOnlyManagerCanAddAdapter() public {
        vm.prank(address(0x1));
        vm.expectRevert();
        registry.addAdapter(address(adapter));
    }
}
