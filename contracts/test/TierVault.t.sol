// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {StrategyRegistry} from "../src/core/StrategyRegistry.sol";
import {RiskConfig} from "../src/core/RiskConfig.sol";
import {GoldVault} from "../src/core/GoldVault.sol";
import {MockYieldAdapter} from "../src/adapters/MockYieldAdapter.sol";

contract TierVaultTest is Test {
    GoldVault vault;
    MockERC20 usdc;
    StrategyRegistry reg;
    RiskConfig risk;
    address admin = address(this);

    function setUp() public {
        usdc = new MockERC20("mUSDC","mUSDC",6);
        usdc.mint(address(this), 10_000e6);
        reg = new StrategyRegistry(admin);
        risk = new RiskConfig(admin, 3000, 4000, 5000);
        vault = new GoldVault(usdc, admin, reg, risk);

        MockYieldAdapter A = new MockYieldAdapter(usdc, address(vault));
        MockYieldAdapter B = new MockYieldAdapter(usdc, address(vault));
        reg.addAdapter(address(A)); reg.addAdapter(address(B));
        address[] memory as_ = new address[](2);
        as_[0] = address(A); as_[1] = address(B);
        uint16[] memory w = new uint16[](2);
        w[0] = 6000; w[1] = 4000;
        vault.setTargetWeights(as_, w);
    }

    function testDepositWithdraw() public {
        usdc.approve(address(vault), 1_000e6);
        uint256 shares = vault.deposit(1_000e6, address(this));
        assertGt(shares, 0);
        vault.rebalance();
        // withdraw half
        uint256 out = vault.redeem(shares/2, address(this), address(this));
        assertApproxEqAbs(out, 500_000_000, 10); // ~500 USDC out
    }
}
