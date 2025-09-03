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

contract DeployMinimal is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        address admin = vm.addr(pk);
        
        // Deploy tokens
        MockERC20 usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        MockERC20 weth = new MockERC20("Mock WETH", "mWETH", 18);
        usdc.mint(admin, 10_000_000e6);
        weth.mint(admin, 1_000e18);
        
        // Deploy core
        StrategyRegistry reg = new StrategyRegistry(admin);
        RiskConfig goldRisk = new RiskConfig(admin, 3000, 4000, 2000);
        RiskConfig silverRisk = new RiskConfig(admin, 3500, 4500, 2500);
        RiskConfig bronzeRisk = new RiskConfig(admin, 2000, 2500, 3000);
        
        // Deploy vaults
        GoldVault gold = new GoldVault(ERC20(address(usdc)), admin, reg, goldRisk);
        SilverVault silver = new SilverVault(ERC20(address(usdc)), admin, reg, silverRisk);
        BronzeVault bronze = new BronzeVault(ERC20(address(weth)), admin, reg, bronzeRisk);
        
        // Deploy and configure adapters
        MockYieldAdapter goldA = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter goldB = new MockYieldAdapter(usdc, address(gold));
        reg.addAdapter(address(goldA));
        reg.addAdapter(address(goldB));
        
        address[] memory gAs = new address[](2);
        gAs[0] = address(goldA);
        gAs[1] = address(goldB);
        uint16[] memory gW = new uint16[](2);
        gW[0] = 6000;
        gW[1] = 4000;
        gold.setTargetWeights(gAs, gW);
        
        goldA.setApr(0.045e18);
        goldB.setApr(0.035e18);
        
        // Seed Gold vault
        usdc.approve(address(gold), 1_000e6);
        gold.deposit(1_000e6, admin);
        gold.rebalance();
        
        console2.log("USDC:", address(usdc));
        console2.log("WETH:", address(weth));
        console2.log("Gold:", address(gold));
        console2.log("Silver:", address(silver));
        console2.log("Bronze:", address(bronze));
        
        vm.stopBroadcast();
    }
}
