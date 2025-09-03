#!/bin/bash

# Yield Park Setup Script
echo "🚀 Setting up Yield Park - DeFi Yield Tiers"

# Install dependencies
echo "📦 Installing dependencies..."
pnpm install

# Setup contracts
echo "🔧 Setting up contracts..."
cd contracts

# Initialize Foundry if not already done
if [ ! -d "lib" ]; then
    echo "Initializing Foundry..."
    forge init --commit .
fi

# Install OpenZeppelin contracts
echo "Installing OpenZeppelin contracts..."
forge install openzeppelin/openzeppelin-contracts@v5.0.2

# Install forge-std
echo "Installing forge-std..."
forge install foundry-rs/forge-std@v1.9.6

# Build contracts
echo "Building contracts..."
forge build

cd ..

# Setup agent
echo "🤖 Setting up agent..."
cd agent
pnpm install
cd ..

# Setup web
echo "🌐 Setting up web..."
cd web
pnpm install
cd ..

echo "✅ Setup complete!"
echo ""
echo "Next steps:"
echo "1. Start a local chain: anvil"
echo "2. Deploy contracts: cd contracts && export PRIVATE_KEY=0xYOURANVILPK && forge script script/Deploy.s.sol:Deploy --broadcast --rpc-url http://127.0.0.1:8545"
echo "3. Copy vault addresses to agent/.env and web/.env.local"
echo "4. Start agent: cd agent && pnpm dev"
echo "5. Start web: cd web && pnpm dev"
echo ""
echo "Visit http://localhost:3000 to see your Yield Park dashboard!"
