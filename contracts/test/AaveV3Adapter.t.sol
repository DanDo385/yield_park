// SPDX-License-Identifier: MIT
pragma solidity ^0.8.24;

import "forge-std/Test.sol";
import {MockERC20} from "../src/mocks/MockERC20.sol";
import {AaveV3Adapter} from "../src/adapters/AaveV3Adapter.sol";
import {IStrategyAdapter} from "../src/interfaces/IStrategyAdapter.sol";
import {GoldVault} from "../src/core/GoldVault.sol";
import {StrategyRegistry} from "../src/core/StrategyRegistry.sol";
import {RiskConfig} from "../src/core/RiskConfig.sol";

// Mock Aave interfaces for testing
contract MockAavePool {
    mapping(address => uint256) public balances;
    mapping(address => uint256) public liquidityRates;
    
    function supply(address asset, uint256 amount, address onBehalfOf, uint16) external {
        balances[onBehalfOf] += amount;
    }
    
    function withdraw(address asset, uint256 amount, address to) external returns (uint256) {
        uint256 available = balances[msg.sender];
        uint256 toWithdraw = amount > available ? available : amount;
        balances[msg.sender] -= toWithdraw;
        MockERC20(asset).transfer(to, toWithdraw);
        return toWithdraw;
    }
    
    function getReserveData(address asset) external view returns (ReserveData memory) {
        return ReserveData({
            configuration: ReserveConfigurationMap(0),
            liquidityIndex: 0,
            currentLiquidityRate: uint128(liquidityRates[asset]),
            variableBorrowIndex: 0,
            currentVariableBorrowRate: 0,
            currentStableBorrowRate: 0,
            lastUpdateTimestamp: 0,
            aTokenAddress: address(0),
            stableDebtTokenAddress: address(0),
            variableDebtTokenAddress: address(0),
            interestRateStrategyAddress: address(0),
            id: 0
        });
    }
    
    function setLiquidityRate(address asset, uint256 rate) external {
        liquidityRates[asset] = rate;
    }
}

contract MockAToken is MockERC20 {
    constructor(string memory name, string memory symbol, uint8 decimals) 
        MockERC20(name, symbol, decimals) {}
}

struct ReserveConfigurationMap { uint256 data; }
struct ReserveData {
    ReserveConfigurationMap configuration;
    uint128 liquidityIndex;
    uint128 currentLiquidityRate;
    uint128 variableBorrowIndex;
    uint128 currentVariableBorrowRate;
    uint128 currentStableBorrowRate;
    uint40 lastUpdateTimestamp;
    address aTokenAddress;
    address stableDebtTokenAddress;
    address variableDebtTokenAddress;
    address interestRateStrategyAddress;
    uint8 id;
}

contract AaveV3AdapterTest is Test {
    AaveV3Adapter adapter;
    MockERC20 usdc;
    MockAToken aUsdc;
    MockAavePool pool;
    GoldVault vault;
    StrategyRegistry registry;
    RiskConfig risk;
    address admin = address(this);

    function setUp() public {
        usdc = new MockERC20("USDC", "USDC", 6);
        aUsdc = new MockAToken("aUSDC", "aUSDC", 6);
        pool = new MockAavePool();
        
        registry = new StrategyRegistry(admin);
        risk = new RiskConfig(admin, 5000, 5000, 5000);
        vault = new GoldVault(usdc, admin, registry, risk);
        
        adapter = new AaveV3Adapter(usdc, address(vault), address(pool), aUsdc);
        
        registry.addAdapter(address(adapter));
        
        // Set up vault with adapter
        address[] memory adapters_ = new address[](1);
        adapters_[0] = address(adapter);
        uint16[] memory weights = new uint16[](1);
        weights[0] = 10000;
        vault.setTargetWeights(adapters_, weights);
        
        // Mint tokens
        usdc.mint(address(this), 100_000e6);
        usdc.mint(address(vault), 100_000e6);
    }

    function testAsset() public {
        assertEq(adapter.asset(), address(usdc));
    }

    function testDeposit() public {
        usdc.approve(address(adapter), 1000e6);
        uint256 shares = adapter.deposit(1000e6);
        assertGt(shares, 0);
        assertEq(adapter.totalAssets(), 1000e6);
    }

    function testWithdraw() public {
        // First deposit
        usdc.approve(address(adapter), 1000e6);
        adapter.deposit(1000e6);
        
        // Then withdraw
        uint256 withdrawn = adapter.withdraw(500e6);
        assertEq(withdrawn, 500e6);
        assertEq(adapter.totalAssets(), 500e6);
    }

    function testCurrentApr() public {
        // Set mock liquidity rate (5% APR in ray format)
        uint256 rate5Percent = 0.05e27; // 5% in ray
        pool.setLiquidityRate(address(usdc), rate5Percent);
        
        uint256 apr = adapter.currentApr();
        assertApproxEqAbs(apr, 0.05e18, 1e15); // 5% with small tolerance
    }

    function testOnlyVaultCanDeposit() public {
        usdc.approve(address(adapter), 1000e6);
        vm.prank(address(0x1));
        vm.expectRevert("AaveV3Adapter: only vault");
        adapter.deposit(1000e6);
    }

    function testOnlyVaultCanWithdraw() public {
        vm.prank(address(0x1));
        vm.expectRevert("AaveV3Adapter: only vault");
        adapter.withdraw(1000e6);
    }

    function testHarvest() public {
        // Harvest should not revert and should emit event
        vm.expectEmit(true, false, false, true);
        emit IStrategyAdapter.Harvest(0, 0);
        adapter.harvest();
    }
}
