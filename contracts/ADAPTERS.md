# Yield Park Adapters

This directory contains strategy adapters that integrate with various DeFi protocols to generate yield for the Gold, Silver, and Bronze vault tiers.

## Adapter Interface

All adapters implement the `IStrategyAdapter` interface:

```solidity
interface IStrategyAdapter {
    function asset() external view returns (address);
    function totalAssets() external view returns (uint256);
    function currentApr() external view returns (uint256);
    function deposit(uint256 assets) external returns (uint256);
    function withdraw(uint256 assets) external returns (uint256);
    function harvest() external;
}
```

## Available Adapters

### 1. AaveV3Adapter
**Protocol**: Aave V3  
**Risk Level**: Low (Gold tier)  
**APY Range**: 4-6%  
**Assets**: USDC, USDT, DAI, WETH, etc.

**Features**:
- Supplies underlying assets to Aave V3
- Holds aTokens (1:1 with underlying, accrues interest)
- Real-time APR via `getReserveData().currentLiquidityRate`
- Automatic interest accrual

**Deployment**:
```solidity
AaveV3Adapter adapter = new AaveV3Adapter(
    IERC20(usdc),           // underlying asset
    address(vault),         // vault address
    AAVE_POOL,             // Aave V3 pool address
    IERC20(A_USDC)         // aToken address
);
```

### 2. CompoundV3Adapter (Comet)
**Protocol**: Compound V3  
**Risk Level**: Low-Medium (Silver tier)  
**APY Range**: 5-8%  
**Assets**: USDC, USDT, WETH, etc.

**Features**:
- Supplies base assets to Comet markets
- Internal balance tracking (can be replaced with on-chain reads)
- Best-effort APR calculation via utilization and supply rates
- Interest accrues within Comet

**Deployment**:
```solidity
CompoundV3Adapter adapter = new CompoundV3Adapter(
    IERC20(usdc),          // underlying asset
    address(vault),        // vault address
    COMET_USDC            // Comet market address
);
```

### 3. MakerDsrAdapter (sDAI)
**Protocol**: Maker DSR  
**Risk Level**: Lowest (Gold tier)  
**APY Range**: 3-5%  
**Assets**: DAI only

**Features**:
- Deposits DAI into sDAI (ERC-4626)
- Automatic yield accrual via share price appreciation
- Precise asset accounting via `convertToAssets()`
- Requires DAI-denominated vault

**Deployment**:
```solidity
MakerDsrAdapter adapter = new MakerDsrAdapter(
    IERC20(dai),           // DAI token
    SDAI_ADDRESS,         // sDAI address
    address(vault)        // vault address
);
```

### 4. UniswapV3LPAdapter
**Protocol**: Uniswap V3  
**Risk Level**: Medium (Silver tier)  
**APY Range**: 5-15% (LP fees)  

**Features**:
- Concentrated liquidity positions
- Configurable fee tiers (0.05%, 0.3%, 1%)
- Automatic fee collection
- Price range management

### 5. PendleSYAdapter
**Protocol**: Pendle Finance  
**Risk Level**: Medium (Silver tier)  
**APY Range**: 8-20%  

**Features**:
- Standardized yield token wrapper
- ERC-4626 compatible interface
- Yield tokenization
- Flexible maturity management

### 6. UsdcToDaiSDaiAdapter
**Protocol**: Composite (Uniswap V3 + Maker DSR)  
**Risk Level**: Low (Gold tier)  
**APY Range**: 3-5%  

**Features**:
- USDC to DAI swapping via Uniswap V3
- DAI to sDAI conversion for DSR yield
- Configurable slippage protection
- Bidirectional conversion

### 7. MockYieldAdapter
**Protocol**: Mock (Testing)  
**Risk Level**: N/A  
**APY Range**: Configurable  

**Features**:
- For testing and demonstration
- Configurable APR via `setApr()`
- Simulated yield generation
- Not for production use

## Protocol Addresses

### Ethereum Mainnet
```solidity
// Aave V3
address AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
address A_USDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
address A_DAI = 0x018008bfb33d285247A21d44E50697654f754e63;

// Compound V3
address COMET_USDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;
address COMET_USDT = 0xF25212E676D1F7F89Cd72fFEe66158f541246445;

// Maker DSR
address SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;
```

### Base
```solidity
// Aave V3
address AAVE_POOL = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
address A_USDC = 0x4e65fE4DbA92790696d040ac24Aa4147083695dC;

// Compound V3
address COMET_USDC = 0x2FAF487A4414Fe72e8f4421F22938d77e240Ec56;
```

### Arbitrum
```solidity
// Aave V3
address AAVE_POOL = 0x794a61358D6845594F94dc1DB02A252b5b4814aD;
address A_USDC = 0x625E7708f30cA75bfd92586e17077590C60eb4cD;

// Compound V3
address COMET_USDC = 0xA17581A9E3356d9A858b789D68B4d866e593aE94;
```

## Integration Guide

### 1. Choose Your Adapters
Select adapters based on your risk tolerance and target yield:

- **Gold Tier**: AaveV3Adapter, MakerDsrAdapter
- **Silver Tier**: CompoundV3Adapter, AaveV3Adapter
- **Bronze Tier**: Higher risk strategies (to be added)

### 2. Deploy Adapters
```solidity
// Deploy adapter
AaveV3Adapter adapter = new AaveV3Adapter(asset, vault, pool, aToken);

// Add to registry
registry.addAdapter(address(adapter));

// Set target weights
address[] memory adapters = new address[](1);
adapters[0] = address(adapter);
uint16[] memory weights = new uint16[](1);
weights[0] = 10000; // 100%
vault.setTargetWeights(adapters, weights);
```

### 3. Monitor Performance
- Track `totalAssets()` for position size
- Monitor `currentApr()` for yield rates
- Use `harvest()` to compound rewards

## Security Considerations

1. **Access Control**: All adapters use `onlyVault` modifier
2. **Safe Approvals**: Uses OpenZeppelin's SafeERC20
3. **Error Handling**: Graceful fallbacks for external calls
4. **Asset Validation**: Ensures asset compatibility with vault

## Adding New Adapters

To add a new protocol adapter:

1. Implement `IStrategyAdapter` interface
2. Add `onlyVault` access control
3. Use SafeERC20 for token operations
4. Add comprehensive error handling
5. Write tests for all functions
6. Update this documentation

## Testing

Run adapter tests:
```bash
forge test --match-contract *Adapter
```

Test specific adapter:
```bash
forge test --match-contract AaveV3Adapter
```
