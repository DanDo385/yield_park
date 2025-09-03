// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Script.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {StrategyRegistry} from "../src/core/StrategyRegistry.sol";
import {RiskConfig} from "../src/core/RiskConfig.sol";
import {GoldVault} from "../src/core/GoldVault.sol";
import {SilverVault} from "../src/core/SilverVault.sol";
import {BronzeVault} from "../src/core/BronzeVault.sol";
import {MockYieldAdapter} from "../src/adapters/MockYieldAdapter.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

/**
 * @title DeploySimple
 * @notice Simple deployment script for local testing with mock adapters
 * 
 * Usage:
 * forge script script/DeploySimple.s.sol:DeploySimple --broadcast --rpc-url http://127.0.0.1:8545
 */
contract DeploySimple is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        address admin = vm.addr(pk);
        
        // Deploy tokens
        MockERC20 usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        MockERC20 weth = new MockERC20("Mock WETH", "mWETH", 18);
        
        // Mint tokens
        usdc.mint(admin, 10_000_000e6);
        weth.mint(admin, 1_000e18);
        
        // Deploy registry
        StrategyRegistry reg = new StrategyRegistry(admin);
        
        // Deploy risk configs
        RiskConfig goldRisk = new RiskConfig(admin, 3000, 4000, 2000);
        RiskConfig silverRisk = new RiskConfig(admin, 3500, 4500, 2500);
        RiskConfig bronzeRisk = new RiskConfig(admin, 2000, 2500, 3000);
        
        // Deploy vaults
        GoldVault gold = new GoldVault(ERC20(address(usdc)), admin, reg, goldRisk);
        SilverVault silver = new SilverVault(ERC20(address(usdc)), admin, reg, silverRisk);
        BronzeVault bronze = new BronzeVault(ERC20(address(weth)), admin, reg, bronzeRisk);
        
        // Deploy mock adapters
        MockYieldAdapter goldA = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter goldB = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter silverA = new MockYieldAdapter(usdc, address(silver));
        MockYieldAdapter silverB = new MockYieldAdapter(usdc, address(silver));
        MockYieldAdapter bronzeA = new MockYieldAdapter(weth, address(bronze));
        MockYieldAdapter bronzeB = new MockYieldAdapter(weth, address(bronze));
        
        // Add adapters to registry
        reg.addAdapter(address(goldA));
        reg.addAdapter(address(goldB));
        reg.addAdapter(address(silverA));
        reg.addAdapter(address(silverB));
        reg.addAdapter(address(bronzeA));
        reg.addAdapter(address(bronzeB));
        
        // Set target weights for Gold
        address[] memory gAs = new address[](2);
        gAs[0] = address(goldA);
        gAs[1] = address(goldB);
        uint16[] memory gW = new uint16[](2);
        gW[0] = 6000;
        gW[1] = 4000;
        gold.setTargetWeights(gAs, gW);
        
        // Set target weights for Silver
        address[] memory sAs = new address[](2);
        sAs[0] = address(silverA);
        sAs[1] = address(silverB);
        uint16[] memory sW = new uint16[](2);
        sW[0] = 5000;
        sW[1] = 5000;
        silver.setTargetWeights(sAs, sW);
        
        // Set target weights for Bronze
        address[] memory bAs = new address[](2);
        bAs[0] = address(bronzeA);
        bAs[1] = address(bronzeB);
        uint16[] memory bW = new uint16[](2);
        bW[0] = 7000;
        bW[1] = 3000;
        bronze.setTargetWeights(bAs, bW);
        
        // Set demo APRs
        goldA.setApr(0.045e18); // 4.5%
        goldB.setApr(0.035e18); // 3.5%
        silverA.setApr(0.07e18); // 7%
        silverB.setApr(0.09e18); // 9%
        bronzeA.setApr(0.14e18); // 14%
        bronzeB.setApr(0.22e18); // 22%
        
        // Seed vaults with $1,000 each
        usdc.approve(address(gold), 1_000e6);
        gold.deposit(1_000e6, admin);
        
        usdc.approve(address(silver), 1_000e6);
        silver.deposit(1_000e6, admin);
        
        weth.approve(address(bronze), 333333333333333333);
        bronze.deposit(333333333333333333, admin);
        
        // Initial rebalance
        gold.rebalance();
        silver.rebalance();
        bronze.rebalance();
        
        // Log deployment
        console2.log("=== YIELD PARK DEPLOYMENT ===");
        console2.log("USDC:", address(usdc));
        console2.log("WETH:", address(weth));
        console2.log("Gold Vault:", address(gold));
        console2.log("Silver Vault:", address(silver));
        console2.log("Bronze Vault:", address(bronze));
        console2.log("Registry:", address(reg));
        console2.log("=== DEPLOYMENT COMPLETE ===");
        
        vm.stopBroadcast();
    }
}
