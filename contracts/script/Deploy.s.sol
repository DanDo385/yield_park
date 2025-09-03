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

contract Deploy is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        address admin = vm.addr(pk);
        
        // Deploy tokens and core contracts
        (MockERC20 usdc, MockERC20 weth, StrategyRegistry reg) = deployTokensAndCore(admin);
        
        // Deploy vaults
        (GoldVault gold, SilverVault silver, BronzeVault bronze) = deployVaults(admin, usdc, weth, reg);
        
        // Deploy and configure adapters
        deployAndConfigureAdapters(usdc, weth, gold, silver, bronze, reg);
        
        // Seed and configure vaults
        seedVaults(usdc, weth, gold, silver, bronze, admin);

        console2.log("USDC:", address(usdc));
        console2.log("WETH:", address(weth));
        console2.log("Gold:", address(gold));
        console2.log("Silver:", address(silver));
        console2.log("Bronze:", address(bronze));

        vm.stopBroadcast();
    }

    function deployTokensAndCore(address admin) internal returns (MockERC20 usdc, MockERC20 weth, StrategyRegistry reg) {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        weth = new MockERC20("Mock WETH", "mWETH", 18);
        reg = new StrategyRegistry(admin);
        
        usdc.mint(admin, 10_000_000e6);
        weth.mint(admin, 1_000e18);
    }

    function deployVaults(address admin, MockERC20 usdc, MockERC20 weth, StrategyRegistry reg) 
        internal returns (GoldVault gold, SilverVault silver, BronzeVault bronze) {
        RiskConfig goldRisk = new RiskConfig(admin, 3000, 4000, 2000);
        RiskConfig silverRisk = new RiskConfig(admin, 3500, 4500, 2500);
        RiskConfig bronzeRisk = new RiskConfig(admin, 2000, 2500, 3000);

        gold = new GoldVault(ERC20(address(usdc)), admin, reg, goldRisk);
        silver = new SilverVault(ERC20(address(usdc)), admin, reg, silverRisk);
        bronze = new BronzeVault(ERC20(address(weth)), admin, reg, bronzeRisk);
    }

    function deployAndConfigureAdapters(MockERC20 usdc, MockERC20 weth, GoldVault gold, SilverVault silver, BronzeVault bronze, StrategyRegistry reg) internal {
        MockYieldAdapter goldA = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter goldB = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter silverA = new MockYieldAdapter(usdc, address(silver));
        MockYieldAdapter silverB = new MockYieldAdapter(usdc, address(silver));
        MockYieldAdapter bronzeA = new MockYieldAdapter(weth, address(bronze));
        MockYieldAdapter bronzeB = new MockYieldAdapter(weth, address(bronze));

        reg.addAdapter(address(goldA)); reg.addAdapter(address(goldB));
        reg.addAdapter(address(silverA)); reg.addAdapter(address(silverB));
        reg.addAdapter(address(bronzeA)); reg.addAdapter(address(bronzeB));

        // Set target weights
        address[] memory gAs = new address[](2);
        gAs[0] = address(goldA); gAs[1] = address(goldB);
        uint16[] memory gW = new uint16[](2);
        gW[0] = 6000; gW[1] = 4000;
        gold.setTargetWeights(gAs, gW);

        address[] memory sAs = new address[](2);
        sAs[0] = address(silverA); sAs[1] = address(silverB);
        uint16[] memory sW = new uint16[](2);
        sW[0] = 5000; sW[1] = 5000;
        silver.setTargetWeights(sAs, sW);

        address[] memory bAs = new address[](2);
        bAs[0] = address(bronzeA); bAs[1] = address(bronzeB);
        uint16[] memory bW = new uint16[](2);
        bW[0] = 7000; bW[1] = 3000;
        bronze.setTargetWeights(bAs, bW);

        // Set demo APRs
        goldA.setApr(0.045e18); goldB.setApr(0.035e18);
        silverA.setApr(0.07e18); silverB.setApr(0.09e18);
        bronzeA.setApr(0.14e18); bronzeB.setApr(0.22e18);
    }

    function seedVaults(MockERC20 usdc, MockERC20 weth, GoldVault gold, SilverVault silver, BronzeVault bronze, address admin) internal {
        usdc.approve(address(gold), 1_000e6);
        gold.deposit(1_000e6, admin);

        usdc.approve(address(silver), 1_000e6);
        silver.deposit(1_000e6, admin);

        weth.approve(address(bronze), 333333333333333333);
        bronze.deposit(333333333333333333, admin);

        gold.rebalance(); silver.rebalance(); bronze.rebalance();
    }
}
