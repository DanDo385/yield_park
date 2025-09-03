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
import {AaveV3Adapter} from "../src/adapters/AaveV3Adapter.sol";
import {CompoundV3Adapter} from "../src/adapters/CompoundV3Adapter.sol";
import {MakerDsrAdapter} from "../src/adapters/MakerDsrAdapter.sol";
import {UniswapV3LPAdapter} from "../src/adapters/UniswapV3LPAdapter.sol";
import {PendleSYAdapter} from "../src/adapters/PendleSYAdapter.sol";
import {UsdcToDaiSDaiAdapter} from "../src/adapters/UsdcToDaiSDaiAdapter.sol";
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

/**
 * @title DeployWithOptions
 * @notice Deployment script with options for different adapter configurations
 * 
 * Usage:
 * 1. Mock adapters only (default): forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast
 * 2. With real adapters: DEPLOY_REAL_ADAPTERS=true forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast
 * 3. With advanced adapters: DEPLOY_ADVANCED_ADAPTERS=true forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast
 * 
 * Environment variables:
 * - DEPLOY_REAL_ADAPTERS: Deploy Aave, Compound, Maker DSR adapters (requires real addresses)
 * - DEPLOY_ADVANCED_ADAPTERS: Deploy Uniswap V3, Pendle, USDC->sDAI adapters
 * - CHAIN_ID: Chain ID for address selection (1=mainnet, 8453=base, etc.)
 */
contract DeployWithOptions is Script {
    // Mock addresses for local testing
    address constant MOCK_AAVE_POOL = 0x1111111111111111111111111111111111111111;
    address constant MOCK_A_USDC = 0x2222222222222222222222222222222222222222;
    address constant MOCK_COMET_USDC = 0x3333333333333333333333333333333333333333;
    address constant MOCK_SDAI = 0x4444444444444444444444444444444444444444;
    address constant MOCK_DAI = 0x5555555555555555555555555555555555555555;
    address constant MOCK_UNI_ROUTER = 0x6666666666666666666666666666666666666666;
    address constant MOCK_POSM = 0x7777777777777777777777777777777777777777;
    address constant MOCK_SY_USDC = 0x8888888888888888888888888888888888888888;

    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        address admin = vm.addr(pk);
        
        // Deploy core infrastructure
        (MockERC20 usdc, MockERC20 dai, MockERC20 weth, StrategyRegistry reg) = deployCore(admin);
        
        // Deploy vaults
        (GoldVault gold, SilverVault silver, BronzeVault bronze) = deployVaults(admin, usdc, weth, reg);
        
        // Deploy adapters based on options
        deployAdapters(usdc, dai, weth, gold, silver, bronze, reg);
        
        // Seed vaults
        seedVaults(usdc, weth, gold, silver, bronze, admin);

        logDeployment(usdc, dai, weth, gold, silver, bronze, reg);
        vm.stopBroadcast();
    }

    function deployCore(address admin) internal returns (MockERC20 usdc, MockERC20 dai, MockERC20 weth, StrategyRegistry reg) {
        usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        dai = new MockERC20("Mock DAI", "mDAI", 18);
        weth = new MockERC20("Mock WETH", "mWETH", 18);
        reg = new StrategyRegistry(admin);
        
        // Mint tokens for testing
        usdc.mint(admin, 10_000_000e6);
        dai.mint(admin, 10_000_000e18);
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

    function deployAdapters(MockERC20 usdc, MockERC20 dai, MockERC20 weth, GoldVault gold, SilverVault silver, BronzeVault bronze, StrategyRegistry reg) internal {
        bool deployReal = vm.envOr("DEPLOY_REAL_ADAPTERS", false);
        bool deployAdvanced = vm.envOr("DEPLOY_ADVANCED_ADAPTERS", false);

        if (deployReal) {
            deployRealAdapters(usdc, dai, gold, silver, bronze, reg);
        }
        
        if (deployAdvanced) {
            deployAdvancedAdapters(usdc, dai, weth, gold, silver, bronze, reg);
        }
        
        // Always deploy mock adapters as fallback
        deployMockAdapters(usdc, weth, gold, silver, bronze, reg);
    }

    function deployRealAdapters(MockERC20 usdc, MockERC20 dai, GoldVault gold, SilverVault silver, BronzeVault bronze, StrategyRegistry reg) internal {
        console2.log("Deploying real protocol adapters...");
        
        // Aave V3 USDC (Gold tier)
        AaveV3Adapter goldAave = new AaveV3Adapter(
            usdc, 
            address(gold), 
            MOCK_AAVE_POOL, 
            ERC20(MOCK_A_USDC)
        );
        reg.addAdapter(address(goldAave));

        // Compound V3 USDC (Silver tier)
        CompoundV3Adapter silverComet = new CompoundV3Adapter(
            usdc, 
            address(silver), 
            MOCK_COMET_USDC
        );
        reg.addAdapter(address(silverComet));

        // Maker DSR sDAI (Gold tier - requires DAI vault)
        GoldVault goldDai = new GoldVault(ERC20(address(dai)), address(this), reg, new RiskConfig(address(this), 3000, 4000, 2000));
        MakerDsrAdapter goldDsr = new MakerDsrAdapter(
            dai, 
            MOCK_SDAI, 
            address(goldDai)
        );
        reg.addAdapter(address(goldDsr));
    }

    function deployAdvancedAdapters(MockERC20 usdc, MockERC20 dai, MockERC20 weth, GoldVault gold, SilverVault silver, BronzeVault bronze, StrategyRegistry reg) internal {
        console2.log("Deploying advanced adapters...");
        
        // Uniswap V3 LP (Silver tier)
        UniswapV3LPAdapter silverUni = new UniswapV3LPAdapter(
            usdc,
            weth,
            address(silver),
            MOCK_UNI_ROUTER,
            MOCK_POSM,
            500, // 0.05% fee
            -46080, // tick lower
            -45500  // tick upper
        );
        reg.addAdapter(address(silverUni));

        // Pendle SY (Silver tier)
        PendleSYAdapter silverPendle = new PendleSYAdapter(
            usdc,
            address(silver),
            MOCK_SY_USDC
        );
        reg.addAdapter(address(silverPendle));

        // USDC -> DAI -> sDAI (Gold tier)
        UsdcToDaiSDaiAdapter goldSDai = new UsdcToDaiSDaiAdapter(
            usdc,
            dai,
            MOCK_SDAI,
            address(gold),
            MOCK_UNI_ROUTER,
            500, // 0.05% fee
            50   // 0.5% slippage
        );
        reg.addAdapter(address(goldSDai));
    }

    function deployMockAdapters(MockERC20 usdc, MockERC20 weth, GoldVault gold, SilverVault silver, BronzeVault bronze, StrategyRegistry reg) internal {
        console2.log("Deploying mock adapters...");
        
        // Mock adapters for testing
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
        // Seed $1,000 in each tier
        usdc.approve(address(gold), 1_000e6);
        gold.deposit(1_000e6, admin);

        usdc.approve(address(silver), 1_000e6);
        silver.deposit(1_000e6, admin);

        weth.approve(address(bronze), 333333333333333333);
        bronze.deposit(333333333333333333, admin);

        // Initial rebalance
        gold.rebalance(); silver.rebalance(); bronze.rebalance();
    }

    function logDeployment(MockERC20 usdc, MockERC20 dai, MockERC20 weth, GoldVault gold, SilverVault silver, BronzeVault bronze, StrategyRegistry reg) internal {
        console2.log("=== YIELD PARK DEPLOYMENT ===");
        console2.log("USDC:", address(usdc));
        console2.log("DAI:", address(dai));
        console2.log("WETH:", address(weth));
        console2.log("Gold Vault:", address(gold));
        console2.log("Silver Vault:", address(silver));
        console2.log("Bronze Vault:", address(bronze));
        console2.log("Registry:", address(reg));
        console2.log("=== DEPLOYMENT COMPLETE ===");
    }
}
