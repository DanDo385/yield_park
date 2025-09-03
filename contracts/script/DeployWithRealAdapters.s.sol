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
import {ERC20} from "openzeppelin-contracts/token/ERC20/ERC20.sol";

/**
 * @title DeployWithRealAdapters
 * @notice Example deployment script showing how to integrate real protocol adapters
 * 
 * IMPORTANT: Replace placeholder addresses with actual protocol addresses for your target chain
 * 
 * Example addresses (these are PLACEHOLDERS - use real ones):
 * - Aave V3 Pool: 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2 (Ethereum mainnet)
 * - aUSDC: 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c (Ethereum mainnet)
 * - Compound V3 USDC: 0xc3d688B66703497DAA19211EEdff47f25384cdc3 (Ethereum mainnet)
 * - sDAI: 0x83F20F44975D03b1b09e64809B757c47f942BEeA (Ethereum mainnet)
 * - DAI: 0x6B175474E89094C44Da98b954EedeAC495271d0F (Ethereum mainnet)
 */
contract DeployWithRealAdapters is Script {
    function run() external {
        uint256 pk = vm.envUint("PRIVATE_KEY");
        vm.startBroadcast(pk);

        // Admin/signers
        address admin = vm.addr(pk);

        // Mock tokens for demo (replace with real tokens for production)
        MockERC20 usdc = new MockERC20("Mock USDC", "mUSDC", 6);
        MockERC20 dai = new MockERC20("Mock DAI", "mDAI", 18);
        MockERC20 weth = new MockERC20("Mock WETH", "mWETH", 18);

        // Seed the deployer with balances
        usdc.mint(admin, 10_000_000e6);
        dai.mint(admin, 10_000_000e18);
        weth.mint(admin, 1_000e18);

        // Core infra
        StrategyRegistry reg = new StrategyRegistry(admin);
        RiskConfig goldRisk = new RiskConfig(admin, 3000, 4000, 2000);
        RiskConfig silverRisk = new RiskConfig(admin, 3500, 4500, 2500);
        RiskConfig bronzeRisk = new RiskConfig(admin, 2000, 2500, 3000);

        // Vaults
        GoldVault gold = new GoldVault(ERC20(address(usdc)), admin, reg, goldRisk);
        SilverVault silver = new SilverVault(ERC20(address(usdc)), admin, reg, silverRisk);
        BronzeVault bronze = new BronzeVault(ERC20(address(weth)), admin, reg, bronzeRisk);

        // ===== REAL ADAPTERS (replace addresses with actual protocol addresses) =====
        
        // Aave V3 USDC (Gold tier - safest)
        // address AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2; // Ethereum mainnet
        // address A_USDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c; // aUSDC
        // AaveV3Adapter goldAave = new AaveV3Adapter(IERC20(address(usdc)), address(gold), AAVE_POOL, IERC20(A_USDC));
        // reg.addAdapter(address(goldAave));

        // Compound V3 USDC (Silver tier - moderate risk)
        // address COMET_USDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3; // Ethereum mainnet
        // CompoundV3Adapter silverComet = new CompoundV3Adapter(IERC20(address(usdc)), address(silver), COMET_USDC);
        // reg.addAdapter(address(silverComet));

        // Maker DSR sDAI (Gold tier - requires DAI vault)
        // address SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA; // sDAI
        // address DAI_TOKEN = 0x6B175474E89094C44Da98b954EedeAC495271d0F; // DAI
        // GoldVault goldDai = new GoldVault(ERC20(DAI_TOKEN), admin, reg, goldRisk);
        // MakerDsrAdapter goldDsr = new MakerDsrAdapter(IERC20(DAI_TOKEN), SDAI, address(goldDai));
        // reg.addAdapter(address(goldDsr));

        // ===== MOCK ADAPTERS (for demo) =====
        MockYieldAdapter goldA = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter goldB = new MockYieldAdapter(usdc, address(gold));
        MockYieldAdapter silverA = new MockYieldAdapter(usdc, address(silver));
        MockYieldAdapter silverB = new MockYieldAdapter(usdc, address(silver));
        MockYieldAdapter bronzeA = new MockYieldAdapter(weth, address(bronze));
        MockYieldAdapter bronzeB = new MockYieldAdapter(weth, address(bronze));

        // Whitelist mock adapters
        reg.addAdapter(address(goldA)); reg.addAdapter(address(goldB));
        reg.addAdapter(address(silverA)); reg.addAdapter(address(silverB));
        reg.addAdapter(address(bronzeA)); reg.addAdapter(address(bronzeB));

        // Target weights
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

        // Approve & deposit $1,000 in each tier
        usdc.approve(address(gold), 1_000e6);
        gold.deposit(1_000e6, admin);

        usdc.approve(address(silver), 1_000e6);
        silver.deposit(1_000e6, admin);

        weth.approve(address(bronze), 333333333333333333);
        bronze.deposit(333333333333333333, admin);

        // Set demo APRs
        goldA.setApr(0.045e18); goldB.setApr(0.035e18);
        silverA.setApr(0.07e18); silverB.setApr(0.09e18);
        bronzeA.setApr(0.14e18); bronzeB.setApr(0.22e18);

        // Initial rebalance
        gold.rebalance(); silver.rebalance(); bronze.rebalance();

        console2.log("=== DEPLOYMENT ADDRESSES ===");
        console2.log("USDC:", address(usdc));
        console2.log("DAI:", address(dai));
        console2.log("WETH:", address(weth));
        console2.log("Gold:", address(gold));
        console2.log("Silver:", address(silver));
        console2.log("Bronze:", address(bronze));
        console2.log("Registry:", address(reg));
        console2.log("=== ADAPTERS ===");
        console2.log("Gold A:", address(goldA));
        console2.log("Gold B:", address(goldB));
        console2.log("Silver A:", address(silverA));
        console2.log("Silver B:", address(silverB));
        console2.log("Bronze A:", address(bronzeA));
        console2.log("Bronze B:", address(bronzeB));

        vm.stopBroadcast();
    }
}
