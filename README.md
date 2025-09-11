# Yield Park - DeFi Yield Tiers (Gold/Silver/Bronze)

A production-grade DeFi application that allocates crypto into staking, liquidity pools, lending, strategy vaults, and yield farming through three risk-tier ERC-4626 vault tokens:

- **Gold** = Safest, stablecoin-only (T-bill/repo-backed stables & sDAI/DSR-linked sources)
- **Silver** = Mostly stablecoins, higher yield via incentives/rotations  
- **Bronze** = Non-stable crypto assets, diversified and actively rotated

Each tier is an ERC-4626 vault with adapters to whitelisted protocols. Off-chain automation continuously monitors TVL/APR/risk, suggests rebalances, and executes within on-chain guardrails.

## Quick Start (Local Development)

1. **Install dependencies**: `pnpm i`
2. **Setup contracts**: `cd contracts && forge install && forge build`
3. **Start local chain**: In a new terminal run `anvil`
4. **Deploy & seed $1,000 per tier**: 
   ```bash
   cd contracts
   export PRIVATE_KEY=0xYOURANVILPK  # Use account[0] from anvil logs
   forge script script/DeployMinimal.s.sol:DeployMinimal --broadcast --rpc-url http://127.0.0.1:8545
   ```
5. **Start agent**: `cd agent && pnpm dev`
6. **Start web app**: `cd web && pnpm dev` then open http://localhost:3000

## Troubleshooting

If you encounter IDE errors or build issues, see [TROUBLESHOOTING.md](TROUBLESHOOTING.md) for detailed solutions.

**Quick fixes:**
- **TypeScript errors**: `cd web && pnpm add -D @types/node`
- **Solidity import errors**: Open `yield_park.code-workspace` in VS Code
- **Build errors**: Use `script/DeployMinimal.s.sol` for deployment

## Architecture

- **Contracts**: Foundry + Solidity with ERC-4626 vaults and strategy adapters
- **Agent**: TypeScript rebalancing agent with DeFiLlama/Dune data integration
- **Web**: Next.js + wagmi + viem + Tailwind CSS

## Risk Tiers

### Gold Tier (4-6% APY)
- Fiat-backed stablecoins (USDC, USDT, DAI)
- Maker DSR/sDAI integration
- Aave/Compound/Morpho lending
- Max 30% per protocol, 40% per asset

### Silver Tier (6-10% APY)  
- Boosted stablecoin strategies
- Pendle fixed/boosted yield
- Maple on-chain credit pools
- Max 35-40% per protocol

### Bronze Tier (10-25%+ APY)
- LSTs/LRTs (wstETH, weETH)
- Volatile LPs and yield farming
- Pendle YT/PT positions
- Max 15-20% per position

## Real Protocol Adapters

The project includes production-ready adapters for major DeFi protocols:

### Available Adapters
- **AaveV3Adapter**: Aave V3 lending (4-6% APY, Gold tier)
- **CompoundV3Adapter**: Compound V3 Comet markets (5-8% APY, Silver tier)  
- **MakerDsrAdapter**: Maker DSR via sDAI (3-5% APY, Gold tier)
- **MockYieldAdapter**: For testing and demonstration

### Integration Examples
See `contracts/script/DeployWithRealAdapters.s.sol` for examples of how to deploy with real protocol integrations.

### Protocol Addresses
Check `contracts/ADAPTERS.md` for verified addresses across Ethereum, Base, and Arbitrum.

## Next Steps



1. **Deploy with real adapters** using the provided examples
2. **Deploy to L2** (Base, Arbitrum, etc.) with appropriate protocol addresses
3. **Integrate real price oracles** (Chainlink)
4. **Add governance and timelock mechanisms**
5. **Implement comprehensive monitoring and alerting**
