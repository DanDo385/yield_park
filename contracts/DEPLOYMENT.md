# Yield Park Deployment Guide

This guide covers different deployment options for Yield Park, from local testing to production deployments.

## Quick Start (Local Testing)

### 1. Start Local Chain
```bash
# In a new terminal
anvil
```

### 2. Deploy with Mock Adapters (Default)
```bash
cd contracts
export PRIVATE_KEY=0xYOURANVILPK  # Use account[0] from anvil logs
forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast --rpc-url http://127.0.0.1:8545
```

### 3. Deploy with Real Protocol Adapters
```bash
export DEPLOY_REAL_ADAPTERS=true
forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast --rpc-url http://127.0.0.1:8545
```

### 4. Deploy with Advanced Adapters
```bash
export DEPLOY_ADVANCED_ADAPTERS=true
forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast --rpc-url http://127.0.0.1:8545
```

## Deployment Options

### Option 1: Mock Adapters Only (Default)
- **Use Case**: Local testing, development
- **Adapters**: MockYieldAdapter only
- **APY**: Configurable (4.5%, 3.5%, 7%, 9%, 14%, 22%)
- **Risk**: None (simulated)

### Option 2: Real Protocol Adapters
- **Use Case**: Testing with real protocol interfaces
- **Adapters**: AaveV3, CompoundV3, MakerDsr
- **APY**: Real protocol rates
- **Risk**: Low (uses mock protocol addresses)

### Option 3: Advanced Adapters
- **Use Case**: Full feature testing
- **Adapters**: UniswapV3LP, PendleSY, UsdcToDaiSDai
- **APY**: Variable (LP fees, Pendle yields, DSR)
- **Risk**: Medium (complex strategies)

## Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEPLOY_REAL_ADAPTERS` | `false` | Deploy Aave, Compound, Maker DSR adapters |
| `DEPLOY_ADVANCED_ADAPTERS` | `false` | Deploy Uniswap V3, Pendle, USDC->sDAI adapters |
| `CHAIN_ID` | `1` | Chain ID for address selection |
| `PRIVATE_KEY` | Required | Private key for deployment |

## Protocol Addresses

### Ethereum Mainnet
```solidity
// Aave V3
address AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
address A_USDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;

// Compound V3
address COMET_USDC = 0xc3d688B66703497DAA19211EEdff47f25384cdc3;

// Maker DSR
address SDAI = 0x83F20F44975D03b1b09e64809B757c47f942BEeA;
address DAI = 0x6B175474E89094C44Da98b954EedeAC495271d0F;

// Uniswap V3
address UNI_ROUTER = 0xE592427A0AEce92De3Edee1F18E0157C05861564;
address POSM = 0xC36442b4a4522E871399CD717aBDD847Ab11FE88;
```

### Base
```solidity
// Aave V3
address AAVE_POOL = 0xA238Dd80C259a72e81d7e4664a9801593F98d1c5;
address A_USDC = 0x4e65fE4DbA92790696d040ac24Aa4147083695dC;

// Uniswap V3
address UNI_ROUTER = 0x2626664c2603336E57B271c5C0b26F421741e481;
address POSM = 0x03a520b32C04BF3bEEf7BF5e9BDe9C8d6D1C3c6;
```

## Production Deployment

### 1. Update Protocol Addresses
Edit `contracts/script/DeployWithOptions.s.sol` and replace mock addresses with real ones:

```solidity
// Replace these with real addresses
address constant REAL_AAVE_POOL = 0x87870Bca3F3fD6335C3F4ce8392D69350B4fA4E2;
address constant REAL_A_USDC = 0x98C23E9d8f34FEFb1B7BD6a91B7FF122F4e16F5c;
// ... etc
```

### 2. Deploy to Testnet
```bash
# Base Sepolia
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
export RPC_URL=https://sepolia.base.org
forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast --rpc-url $RPC_URL
```

### 3. Deploy to Mainnet
```bash
# Base Mainnet
export PRIVATE_KEY=0xYOUR_PRIVATE_KEY
export RPC_URL=https://mainnet.base.org
forge script script/DeployWithOptions.s.sol:DeployWithOptions --broadcast --rpc-url $RPC_URL --verify
```

## Post-Deployment Setup

### 1. Copy Vault Addresses
After deployment, copy the vault addresses to your environment files:

```bash
# agent/.env
GOLD_VAULT=0x...
SILVER_VAULT=0x...
BRONZE_VAULT=0x...

# web/.env.local
NEXT_PUBLIC_GOLD_VAULT=0x...
NEXT_PUBLIC_SILVER_VAULT=0x...
NEXT_PUBLIC_BRONZE_VAULT=0x...
```

### 2. Start Services
```bash
# Agent
cd agent && pnpm dev

# Web App
cd web && pnpm dev
```

### 3. Verify Deployment
- Visit http://localhost:3000
- Check that vaults show $1,000 initial balance
- Verify P&L tracking works
- Test deposit/withdraw functionality

## Security Considerations

### 1. Access Control
- All adapters use `onlyVault` modifier
- Registry requires `MANAGER_ROLE` for adapter changes
- Risk config requires `MANAGER_ROLE` for parameter changes

### 2. Slippage Protection
- Uniswap V3 adapters use configurable slippage limits
- USDC->sDAI adapter has 0.5% default slippage
- All swaps have minimum output protection

### 3. Emergency Controls
- Vaults can be paused by `MANAGER_ROLE`
- Risk config can pause all operations
- Adapters can be removed from registry

## Monitoring

### 1. Key Metrics
- Total assets per vault
- Adapter allocations
- APR changes
- Slippage events

### 2. Alerts
- Large position changes
- APR drops below thresholds
- Slippage exceeds limits
- Emergency pause events

## Troubleshooting

### Common Issues

1. **"Stack too deep" error**
   - Solution: Use `via_ir = true` in foundry.toml

2. **Import errors**
   - Solution: Check remappings in foundry.toml

3. **Deployment fails**
   - Solution: Verify RPC URL and private key

4. **Adapters not working**
   - Solution: Check protocol addresses and interfaces

### Debug Commands
```bash
# Check deployment
forge script script/DeployWithOptions.s.sol:DeployWithOptions --dry-run

# Run tests
forge test

# Check gas usage
forge script script/DeployWithOptions.s.sol:DeployWithOptions --gas-report
```

## Next Steps

1. **Add Real Price Oracles**: Integrate Chainlink price feeds
2. **Implement Governance**: Add timelock and multisig controls
3. **Add Monitoring**: Set up alerts and dashboards
4. **Optimize Gas**: Reduce deployment and operation costs
5. **Add More Adapters**: Integrate additional DeFi protocols
